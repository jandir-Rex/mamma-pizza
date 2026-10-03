import { apiRequest } from "@/services/api";
import type { Pedido, VarianteInfo } from "@/types/pedido";

type ProductoMenu = {
  nombre: string;
  categoria: {
    areaPreparacion: "HORNO" | "BARRA" | null;
    padre?: { areaPreparacion: "HORNO" | "BARRA" | null } | null;
  };
  variantes: { id: number; tamano: string }[];
};

const PEDIDOS_TTL_MS = 30_000;
const MENU_TTL_MS = 5 * 60_000;
const PEDIDOS_CACHE_MAX_DIAS = 7;

type RangoDia = { desde: string; hasta: string };
type CachePedidos = { pedidos: Pedido[]; guardadoEn: number };

const pedidosCache = new Map<string, CachePedidos>();
const pedidosRequests = new Map<string, Promise<Pedido[]>>();
let variantesCache: Record<number, VarianteInfo> | null = null;
let variantesCacheAt = 0;
let variantesRequest: Promise<Record<number, VarianteInfo>> | null = null;
let variantesCacheVersion = 0;

export function fechaLocalHoy() {
  const hoy = new Date();
  const anio = hoy.getFullYear();
  const mes = String(hoy.getMonth() + 1).padStart(2, "0");
  const dia = String(hoy.getDate()).padStart(2, "0");
  return `${anio}-${mes}-${dia}`;
}

export function rangoDiaLocal(fecha: string): RangoDia {
  const [anio, mes, dia] = fecha.split("-").map(Number);
  const inicio = new Date(anio, mes - 1, dia);
  const fin = new Date(anio, mes - 1, dia + 1);
  return { desde: inicio.toISOString(), hasta: fin.toISOString() };
}

function identidadCachePedidos() {
  try {
    const usuario = JSON.parse(localStorage.getItem("usuario") ?? "null");
    if (!usuario || typeof usuario !== "object") return "anon";

    const id = "id" in usuario ? usuario.id : null;
    const rol = "rol" in usuario ? usuario.rol : null;
    const permisos = "permisos" in usuario && Array.isArray(usuario.permisos)
      ? usuario.permisos.filter((permiso: unknown): permiso is string => typeof permiso === "string").sort().join(",")
      : "";

    return `${id}:${rol}:${permisos}`;
  } catch {
    return "anon";
  }
}

function claveRango({ desde, hasta }: RangoDia) {
  return `${identidadCachePedidos()}|${desde}|${hasta}`;
}

export function leerPedidosCache(rango: RangoDia) {
  return pedidosCache.get(claveRango(rango))?.pedidos ?? null;
}

export function leerVariantesCache() {
  return variantesCache;
}

export function invalidarVariantesMenuCache() {
  variantesCacheVersion += 1;
  variantesCache = null;
  variantesCacheAt = 0;
  variantesRequest = null;
}

export function obtenerPedidos(
  rango: RangoDia,
  forzar = false,
): Promise<Pedido[]> {
  const clave = claveRango(rango);
  const cache = pedidosCache.get(clave);
  if (!forzar && cache && Date.now() - cache.guardadoEn < PEDIDOS_TTL_MS) {
    return Promise.resolve(cache.pedidos);
  }
  const enCurso = pedidosRequests.get(clave);
  if (enCurso) return enCurso;

  const parametros = new URLSearchParams(rango);
  const solicitud = apiRequest<Pedido[]>(`/pedidos?${parametros.toString()}`)
    .then((pedidos) => {
      pedidosCache.delete(clave);
      pedidosCache.set(clave, { pedidos, guardadoEn: Date.now() });
      while (pedidosCache.size > PEDIDOS_CACHE_MAX_DIAS) {
        const claveAntigua = pedidosCache.keys().next().value;
        if (claveAntigua === undefined) break;
        pedidosCache.delete(claveAntigua);
      }
      return pedidos;
    })
    .finally(() => {
      pedidosRequests.delete(clave);
    });

  pedidosRequests.set(clave, solicitud);
  return solicitud;
}

export function obtenerVariantesMenu(
  forzar = false,
): Promise<Record<number, VarianteInfo>> {
  if (
    !forzar &&
    variantesCache !== null &&
    Date.now() - variantesCacheAt < MENU_TTL_MS
  ) {
    return Promise.resolve(variantesCache);
  }
  if (variantesRequest) return variantesRequest;

  const version = variantesCacheVersion;
  variantesRequest = apiRequest<ProductoMenu[]>("/productos/menu")
    .then((productos) => {
      const mapa: Record<number, VarianteInfo> = {};
      productos.forEach((producto) => {
        const areaPreparacion =
          producto.categoria.areaPreparacion ??
          producto.categoria.padre?.areaPreparacion ??
          "HORNO";
        producto.variantes.forEach((variante) => {
          mapa[variante.id] = {
            nombre: producto.nombre,
            tamano: variante.tamano,
            areaPreparacion,
          };
        });
      });
      if (version === variantesCacheVersion) {
        variantesCache = mapa;
        variantesCacheAt = Date.now();
      }
      return mapa;
    })
    .finally(() => {
      if (version === variantesCacheVersion) variantesRequest = null;
    });

  return variantesRequest;
}

export function actualizarPedidosCache(
  rango: RangoDia,
  actualizar: (pedidos: Pedido[]) => Pedido[],
) {
  const clave = claveRango(rango);
  const cache = pedidosCache.get(clave);
  if (!cache) return;
  pedidosCache.set(clave, {
    pedidos: actualizar(cache.pedidos),
    guardadoEn: Date.now(),
  });
}