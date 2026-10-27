// src/pages/Administracion/RegistroPedidos.tsx
import { useEffect, useRef, useState } from "react";
import PanelDetallePedido from "@/components/PanelDetallePedido";
import FilaPedido from "@/components/FilaPedido";
import DrawerCrearPedido from "@/components/DrawerCrearPedido";
import { useAuth } from "@/context/AuthContext";
import {
  actualizarPedidosCache,
  fechaLocalHoy,
  leerPedidosCache,
  leerVariantesCache,
  obtenerPedidos,
  obtenerVariantesMenu,
  rangoDiaLocal,
} from "@/services/pedidosCache";
import { conectarSocket, obtenerSocket } from "@/services/socket";
import {
  etiquetasEstado,
  obtenerCanalOperativo,
  type CanalOperativo,
  type Pedido,
  type VarianteInfo,
} from "@/types/pedido";

// --- ICONOS VECTORIALES PROFESIONALES ---
function TableIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6" {...props}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M2 6h16M5 6v10M15 6v10M2 10h16" />
    </svg>
  );
}

function TakeoutIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6" {...props}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M4 6h12l-1 11H5L4 6Zm3 0V4a3 3 0 0 1 6 0v2" />
    </svg>
  );
}

function TruckIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6" {...props}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M1 3h11v10H1V3Zm11 3h4l3 4v4h-7V6ZM4 17a2 2 0 1 0 0-4 2 2 0 0 0 0 4Zm10 0a2 2 0 1 0 0-4 2 2 0 0 0 0 4Z" />
    </svg>
  );
}

type FiltroEstado =
  | "GESTION"
  | "PENDIENTES"
  | "FINALIZADOS"
  | "CANCELADOS"
  | "ACTIVOS"
  | "SIN_REPARTIDOR";

function esPedidoActivo(pedido: Pedido) {
  return pedido.estado !== "ENTREGADO" && pedido.estado !== "CANCELADO";
}

// Pedido de delivery confirmado que nadie ha tomado: la "pizza al aire"
function esSinRepartidor(pedido: Pedido) {
  return (
    pedido.canal === "DELIVERY" &&
    !pedido.repartidorId &&
    (pedido.estado === "CONFIRMADO" || pedido.estado === "EN_PREPARACION")
  );
}

const PERMISO_POR_CANAL: Record<CanalOperativo, string> = {
  SALON: "pedidos:canal:SALON",
  PARA_LLEVAR: "pedidos:canal:PARA_LLEVAR",
  DELIVERY: "pedidos:canal:DELIVERY",
};

// Red de seguridad: aunque el socket falle (o el rol no reciba eventos), la lista se refresca sola
const SINCRONIZACION_MS = 45_000;

type PedidoParcial = Partial<Pedido> & { id: number };

// El backend puede mandar el pedido directo o envuelto en { pedido }
function extraerPedido(payload: unknown): PedidoParcial | null {
  if (typeof payload !== "object" || payload === null) return null;
  const candidato = "pedido" in payload ? (payload as { pedido: unknown }).pedido : payload;
  if (typeof candidato !== "object" || candidato === null) return null;
  const id = (candidato as { id?: unknown }).id;
  return typeof id === "number" ? (candidato as PedidoParcial) : null;
}

// Mezcla un evento parcial sin dejar un nombre de repartidor "viejo" colgado
function fusionarPedido(base: Pedido, cambios: Partial<Pedido>): Pedido {
  const resultado: Pedido = { ...base, ...cambios };
  if (
    cambios.repartidor === undefined &&
    cambios.repartidorId !== undefined &&
    cambios.repartidorId !== base.repartidorId
  ) {
    resultado.repartidor = cambios.repartidorId === null ? null : undefined;
  }
  return resultado;
}

export default function RegistroPedidos() {
  const { tienePermiso, usuario } = useAuth();
  const [dia] = useState(fechaLocalHoy);
  const [pedidos, setPedidos] = useState<Pedido[]>(() =>
    leerPedidosCache(rangoDiaLocal(fechaLocalHoy())) ?? []
  );
  const [variantesMap, setVariantesMap] = useState<Record<number, VarianteInfo>>(
    () => leerVariantesCache() ?? {}
  );
  const [seleccionado, setSeleccionado] = useState<Pedido | null>(null);
  const [busqueda, setBusqueda] = useState("");

  // Filtros combinados: Canal + Estado
  const [canalFiltro, setCanalFiltro] = useState<CanalOperativo | "TODOS">("TODOS");
  const [filtroEstado, setFiltroEstado] = useState<FiltroEstado>("ACTIVOS");

  const [cargando, setCargando] = useState(() =>
    leerPedidosCache(rangoDiaLocal(fechaLocalHoy())) === null
  );
  const [actualizando, setActualizando] = useState(false);
  const [error, setError] = useState("");
  const [enVivo, setEnVivo] = useState(false);
  const [drawerNuevoPedidoAbierto, setDrawerNuevoPedidoAbierto] = useState(false);
  const esAdmin = usuario?.rol === "ADMIN";
  const puedeGestionarReparto = esAdmin || tienePermiso("reparto:gestion");
  const canalPermitido = (canal: CanalOperativo) =>
    esAdmin || tienePermiso(PERMISO_POR_CANAL[canal]);
  const canalesParaCrear = (["SALON", "PARA_LLEVAR"] as const).filter(canalPermitido);
  const pedidosAutorizados = pedidos.filter((pedido) =>
    canalPermitido(obtenerCanalOperativo(pedido))
  );

  // Siempre apunta a la lista más reciente (lo usan los handlers del socket)
  const pedidosRef = useRef(pedidos);
  pedidosRef.current = pedidos;

  useEffect(() => {
    let activo = true;
    const rango = rangoDiaLocal(dia);

    Promise.all([obtenerPedidos(rango, true), obtenerVariantesMenu()])
      .then(([listaPedidos, menu]) => {
        if (!activo) return;
        setPedidos(listaPedidos);
        setVariantesMap(menu);
      })
      .catch((err: unknown) => {
        if (activo) {
          setError(err instanceof Error ? err.message : "No se pudieron cargar los pedidos");
        }
      })
      .finally(() => {
        if (activo) setCargando(false);
      });

    return () => {
      activo = false;
    };
  }, [dia]);

  // --- TIEMPO REAL (Socket.IO) + sincronización de respaldo ---
  useEffect(() => {
    const rango = rangoDiaLocal(dia);
    let temporizador: ReturnType<typeof setTimeout> | undefined;

    async function sincronizar() {
      try {
        const lista = await obtenerPedidos(rango, true);
        setPedidos(lista);
        setSeleccionado((actual) =>
          actual ? lista.find((p) => p.id === actual.id) ?? actual : actual
        );
      } catch {
        // Silencioso: el botón "Actualizar" sigue disponible y muestra errores
      }
    }

    // Varios eventos seguidos => una sola recarga
    function programarSincronizacion() {
      clearTimeout(temporizador);
      temporizador = setTimeout(sincronizar, 400);
    }

    function alPedidoNuevo() {
      programarSincronizacion();
    }

    function alPedidoActualizado(payload: unknown) {
      const cambios = extraerPedido(payload);
      if (!cambios) {
        programarSincronizacion();
        return;
      }
      // Un pedido que no tenemos: recargamos para traerlo completo
      if (!pedidosRef.current.some((p) => p.id === cambios.id)) {
        programarSincronizacion();
        return;
      }

      const mezclar = (actuales: Pedido[]) =>
        actuales.map((p) => (p.id === cambios.id ? fusionarPedido(p, cambios) : p));
      setPedidos(mezclar);
      actualizarPedidosCache(rango, mezclar);
      setSeleccionado((actual) =>
        actual?.id === cambios.id ? fusionarPedido(actual, cambios) : actual
      );

      // Se asignó un repartidor pero el evento no trajo su nombre: lo pedimos completo
      if (cambios.repartidorId && cambios.repartidor === undefined) {
        programarSincronizacion();
      }
    }

    const intervalo = setInterval(sincronizar, SINCRONIZACION_MS);

    // Ojo: obtenerSocket() primero, conectarSocket() mata un socket que aún está conectándose
    const socket = obtenerSocket() ?? conectarSocket();
    const alConectar = () => {
      setEnVivo(true);
      programarSincronizacion(); // recupera lo que pasó mientras estuvo desconectado
    };
    const alDesconectar = () => setEnVivo(false);

    if (socket) {
      setEnVivo(socket.connected);
      socket.on("connect", alConectar);
      socket.on("disconnect", alDesconectar);
      socket.on("pedido:nuevo", alPedidoNuevo);
      socket.on("pedido:actualizado", alPedidoActualizado);
    }

    return () => {
      clearInterval(intervalo);
      clearTimeout(temporizador);
      if (socket) {
        socket.off("connect", alConectar);
        socket.off("disconnect", alDesconectar);
        socket.off("pedido:nuevo", alPedidoNuevo);
        socket.off("pedido:actualizado", alPedidoActualizado);
      }
    };
  }, [dia]);

  async function refrescarPedidos() {
    setActualizando(true);
    setError("");
    try {
      const rango = rangoDiaLocal(dia);
      const [listaPedidos, menu] = await Promise.all([
        obtenerPedidos(rango, true),
        obtenerVariantesMenu(true),
      ]);
      setPedidos(listaPedidos);
      setVariantesMap(menu);
      setSeleccionado((actual) =>
        actual ? listaPedidos.find((p) => p.id === actual.id) ?? actual : actual
      );
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudieron actualizar los pedidos");
    } finally {
      setActualizando(false);
    }
  }

  function actualizarPedidoLocal(pedidoActualizado: Pedido) {
    const rango = rangoDiaLocal(dia);
    const mezclar = (actuales: Pedido[]) =>
      actuales.map((p) => (p.id === pedidoActualizado.id ? { ...p, ...pedidoActualizado } : p));
    setPedidos(mezclar);
    actualizarPedidosCache(rango, mezclar);
    setSeleccionado((actual) =>
      actual?.id === pedidoActualizado.id ? { ...actual, ...pedidoActualizado } : actual
    );
  }

  // --- FILTRADO INTELIGENTE (Canal + Búsqueda + Estado) ---

  // 1. Conteo por canal: solo pedidos que todavía requieren atención
  const pedidosActivos = pedidosAutorizados.filter(esPedidoActivo);
  const conteoSalon = pedidosAutorizados.filter(
    (p) => obtenerCanalOperativo(p) === "SALON" && esPedidoActivo(p)
  ).length;

  const conteoParaLlevar = pedidosAutorizados.filter(
    (p) => obtenerCanalOperativo(p) === "PARA_LLEVAR" && esPedidoActivo(p)
  ).length;

  const conteoDelivery = pedidosAutorizados.filter(
    (p) => obtenerCanalOperativo(p) === "DELIVERY" && esPedidoActivo(p)
  ).length;

  // Pizzas al aire (de cualquier canal filtrado): alimentan el banner de alerta
  const totalSinRepartidor = pedidosAutorizados.filter(esSinRepartidor).length;

  // 2. Filtrar por Canal seleccionado
  const pedidosPorCanal = pedidosAutorizados.filter((p) => {
    if (canalFiltro === "TODOS") return true;
    return obtenerCanalOperativo(p) === canalFiltro;
  });

  // 3. Filtrar por búsqueda de texto
  const textoBusqueda = busqueda.trim().toLowerCase();
  const pedidosConBusqueda = pedidosPorCanal.filter(
    (p) =>
      p.codigo.toLowerCase().includes(textoBusqueda) ||
      (p.cliente?.nombre && p.cliente.nombre.toLowerCase().includes(textoBusqueda)) ||
      (p.clienteNombre && p.clienteNombre.toLowerCase().includes(textoBusqueda))
  );

  // 4. Filtrar por Estado (Gestión, Pendientes, Finalizados, Sin repartidor)
  const pedidosVisibles = pedidosConBusqueda.filter((p) => {
    if (filtroEstado === "ACTIVOS") return esPedidoActivo(p);
    if (filtroEstado === "GESTION") return ["CONFIRMADO", "EN_PREPARACION", "EN_CAMINO"].includes(p.estado);
    if (filtroEstado === "PENDIENTES") return p.estado === "PENDIENTE_PAGO";
    if (filtroEstado === "FINALIZADOS") return p.estado === "ENTREGADO";
    if (filtroEstado === "SIN_REPARTIDOR") return esSinRepartidor(p);
    return p.estado === "CANCELADO";
  });

  // Conteo de estados sobre el canal actual
  const cantActivos = pedidosConBusqueda.filter(esPedidoActivo).length;
  const cantGestion = pedidosConBusqueda.filter((p) =>
    ["CONFIRMADO", "EN_PREPARACION", "EN_CAMINO"].includes(p.estado)
  ).length;
  const cantPendientes = pedidosConBusqueda.filter((p) => p.estado === "PENDIENTE_PAGO").length;
  const cantFinalizados = pedidosConBusqueda.filter((p) => p.estado === "ENTREGADO").length;
  const cantCancelados = pedidosConBusqueda.filter((p) => p.estado === "CANCELADO").length;
  const cantSinRepartidor = pedidosConBusqueda.filter(esSinRepartidor).length;

  const tabsEstado: { id: FiltroEstado; nombre: string; cant: number; alerta?: boolean }[] = [
    { id: "ACTIVOS", nombre: "Activos", cant: cantActivos },
    { id: "PENDIENTES", nombre: "Pendientes de pago", cant: cantPendientes },
    { id: "GESTION", nombre: "En gestión", cant: cantGestion },
    ...(puedeGestionarReparto && canalPermitido("DELIVERY")
      ? [
          {
            id: "SIN_REPARTIDOR" as const,
            nombre: "Sin repartidor",
            cant: cantSinRepartidor,
            alerta: cantSinRepartidor > 0,
          },
        ]
      : []),
    { id: "FINALIZADOS", nombre: "Finalizados", cant: cantFinalizados },
    { id: "CANCELADOS", nombre: "Cancelados", cant: cantCancelados },
  ];

  return (
    <div className="space-y-5">
      {/* Encabezado Principal */}
      <div className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
        <div>
          <p className="flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400">
            Operaciones en Vivo
            {esAdmin && (
              <span
                className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-bold ${
                  enVivo
                    ? "bg-success-50 text-success-700 dark:bg-success-500/10 dark:text-success-400"
                    : "bg-warning-50 text-warning-700 dark:bg-warning-500/10 dark:text-warning-400"
                }`}
              >
                <span
                  className={`size-1.5 rounded-full ${
                    enVivo ? "bg-success-500" : "animate-pulse bg-warning-500"
                  }`}
                />
                {enVivo ? "Conectado" : "Reconectando..."}
              </span>
            )}
          </p>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Control de Pedidos
          </h1>
        </div>

        <div className="flex flex-wrap items-center gap-2.5">
          {tienePermiso("pedidos:crear") && canalesParaCrear.length > 0 && (
            <button
              type="button"
              onClick={() => setDrawerNuevoPedidoAbierto(true)}
              className="flex h-10 items-center gap-2 rounded-xl bg-brand-500 px-4 text-sm font-bold text-white shadow-sm transition hover:bg-brand-600"
            >
              + Nuevo Pedido
            </button>
          )}

          <button
            type="button"
            onClick={refrescarPedidos}
            disabled={actualizando}
            className="flex h-10 items-center rounded-xl border border-gray-200 bg-white px-3.5 text-sm font-semibold text-gray-700 hover:bg-gray-50 disabled:opacity-50 dark:border-gray-800 dark:bg-gray-900 dark:text-gray-300 dark:hover:bg-gray-800"
          >
            {actualizando ? "Actualizando..." : "Actualizar"}
          </button>

          <input
            type="search"
            placeholder="Buscar código o cliente..."
            value={busqueda}
            onChange={(e) => setBusqueda(e.target.value)}
            className="h-10 w-full rounded-xl border border-gray-200 bg-white px-3.5 text-sm text-gray-800 outline-none focus:border-brand-500 sm:w-56 dark:border-gray-800 dark:bg-gray-900 dark:text-white"
          />
        </div>
      </div>

      {error && (
        <div className="rounded-xl bg-red-50 p-4 text-sm text-red-600 dark:bg-red-950/20 dark:text-red-400">
          {error}
        </div>
      )}

      {/* 🚨 ALERTA: pedidos de delivery que nadie ha tomado */}
      {puedeGestionarReparto && totalSinRepartidor > 0 && (
        <div
          role="alert"
          className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-error-200 bg-error-50 p-3.5 dark:border-error-500/20 dark:bg-error-500/10"
        >
          <p className="text-sm font-bold text-error-700 dark:text-error-400">
            {totalSinRepartidor} pedido{totalSinRepartidor === 1 ? "" : "s"} de delivery sin repartidor
            <span className="ml-2 font-medium opacity-80">
              Asígnalo{totalSinRepartidor === 1 ? "" : "s"} antes de despachar.
            </span>
          </p>
          <button
            type="button"
            onClick={() => {
              setCanalFiltro("DELIVERY");
              setFiltroEstado("SIN_REPARTIDOR");
              setSeleccionado(null);
            }}
            className="rounded-lg bg-error-600 px-3 py-1.5 text-xs font-bold text-white hover:bg-error-700"
          >
            Ver pedidos
          </button>
        </div>
      )}

      {/* 👈 NUEVA BARRA: SEGMENTACIÓN DE LOS 3 CANALES OPERATIVOS */}
      <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
        <button
          type="button"
          onClick={() => {
            setCanalFiltro("TODOS");
            setSeleccionado(null);
          }}
          className={`flex items-center justify-between rounded-xl border p-3.5 transition ${
            canalFiltro === "TODOS"
              ? "border-brand-500 bg-brand-50/60 dark:border-brand-500 dark:bg-brand-950/20"
              : "border-gray-200 bg-white hover:bg-gray-50 dark:border-gray-800 dark:bg-gray-900 dark:hover:bg-gray-800/40"
          }`}
        >
          <span className="text-xs font-bold uppercase tracking-wider text-gray-600 dark:text-gray-300">
            {esAdmin ? "Todos los canales" : "Mis canales"}
          </span>
          <span className="rounded-md bg-gray-100 px-2 py-0.5 text-xs font-black text-gray-800 dark:bg-gray-800 dark:text-white">
            {pedidosActivos.length}
          </span>
        </button>

        {canalPermitido("SALON") && (
          <button
            type="button"
            onClick={() => {
              setCanalFiltro("SALON");
              setSeleccionado(null);
            }}
            className={`flex items-center justify-between rounded-xl border p-3.5 transition ${
              canalFiltro === "SALON"
                ? "border-blue-500 bg-blue-50/60 dark:border-blue-500 dark:bg-blue-950/20"
                : "border-gray-200 bg-white hover:bg-gray-50 dark:border-gray-800 dark:bg-gray-900 dark:hover:bg-gray-800/40"
            }`}
          >
            <div className="flex items-center gap-2">
              <TableIcon className="size-4 text-blue-500" />
              <span className="text-xs font-bold uppercase tracking-wider text-gray-600 dark:text-gray-300">
                En Salón
              </span>
            </div>
            <span className="rounded-md bg-blue-100 px-2 py-0.5 text-xs font-black text-blue-800 dark:bg-blue-950 dark:text-blue-300">
              {conteoSalon}
            </span>
          </button>
        )}

        {canalPermitido("PARA_LLEVAR") && (
          <button
            type="button"
            onClick={() => {
              setCanalFiltro("PARA_LLEVAR");
              setSeleccionado(null);
            }}
            className={`flex items-center justify-between rounded-xl border p-3.5 transition ${
              canalFiltro === "PARA_LLEVAR"
                ? "border-purple-500 bg-purple-50/60 dark:border-purple-500 dark:bg-purple-950/20"
                : "border-gray-200 bg-white hover:bg-gray-50 dark:border-gray-800 dark:bg-gray-900 dark:hover:bg-gray-800/40"
            }`}
          >
            <div className="flex items-center gap-2">
              <TakeoutIcon className="size-4 text-purple-500" />
              <span className="text-xs font-bold uppercase tracking-wider text-gray-600 dark:text-gray-300">
                Para Llevar
              </span>
            </div>
            <span className="rounded-md bg-purple-100 px-2 py-0.5 text-xs font-black text-purple-800 dark:bg-purple-950 dark:text-purple-300">
              {conteoParaLlevar}
            </span>
          </button>
        )}

        {canalPermitido("DELIVERY") && (
          <button
            type="button"
            onClick={() => {
              setCanalFiltro("DELIVERY");
              setSeleccionado(null);
            }}
            className={`flex items-center justify-between rounded-xl border p-3.5 transition ${
              canalFiltro === "DELIVERY"
                ? "border-amber-500 bg-amber-50/60 dark:border-amber-500 dark:bg-amber-950/20"
                : "border-gray-200 bg-white hover:bg-gray-50 dark:border-gray-800 dark:bg-gray-900 dark:hover:bg-gray-800/40"
            }`}
          >
            <div className="flex items-center gap-2">
              <TruckIcon className="size-4 text-amber-500" />
              <span className="text-xs font-bold uppercase tracking-wider text-gray-600 dark:text-gray-300">
                Delivery
              </span>
            </div>
            <span className="rounded-md bg-amber-100 px-2 py-0.5 text-xs font-black text-amber-800 dark:bg-amber-950 dark:text-amber-300">
              {conteoDelivery}
            </span>
          </button>
        )}
      </div>

      {/* Contenedor Principal: Tabla + Panel Detalle */}
      <div className="overflow-hidden rounded-xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-900">

        {/* Filtros por Estado */}
        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-gray-100 px-5 py-3 dark:border-gray-800">
          <div className="flex gap-1 overflow-x-auto">
            {tabsEstado.map((opcion) => (
              <button
                key={opcion.id}
                type="button"
                onClick={() => {
                  setFiltroEstado(opcion.id);
                  setSeleccionado(null);
                }}
                className={`inline-flex items-center gap-2 whitespace-nowrap rounded-lg px-3 py-1.5 text-xs font-bold transition ${
                  filtroEstado === opcion.id
                    ? opcion.alerta
                      ? "bg-error-50 text-error-700 dark:bg-error-500/10 dark:text-error-400"
                      : "bg-brand-50 text-brand-700 dark:bg-brand-500/10 dark:text-brand-400"
                    : opcion.alerta
                      ? "text-error-600 hover:bg-error-50 dark:text-error-400 dark:hover:bg-error-500/10"
                      : "text-gray-500 hover:bg-gray-50 dark:text-gray-400 dark:hover:bg-gray-800"
                }`}
              >
                {opcion.nombre}
                <span className="text-[11px] opacity-70">({opcion.cant})</span>
              </button>
            ))}
          </div>

          <span className="text-xs text-gray-400">
            {pedidosVisibles.length} resultado{pedidosVisibles.length === 1 ? "" : "s"}
          </span>
        </div>

        {/* Listado y Detalle */}
        <div className="flex min-h-80">
          <section className="min-w-0 flex-1" aria-label="Pedidos">
            {cargando ? (
              <p className="px-5 py-10 text-sm text-gray-500">Cargando pedidos...</p>
            ) : pedidosVisibles.length === 0 ? (
              <p className="px-5 py-10 text-sm text-gray-500">
                {filtroEstado === "SIN_REPARTIDOR"
                  ? "Todos los pedidos de delivery tienen repartidor."
                  : "No hay pedidos en este canal y filtro."}
              </p>
            ) : (
              <div className="divide-y divide-gray-100 dark:divide-gray-800">
                {pedidosVisibles.map((pedido) => (
                  <FilaPedido
                    key={pedido.id}
                    pedido={pedido}
                    seleccionado={seleccionado?.id === pedido.id}
                    onClick={() => setSeleccionado(pedido)}
                  />
                ))}
              </div>
            )}
          </section>

          {seleccionado && (
            <PanelDetallePedido
              pedido={seleccionado}
              variantesMap={variantesMap}
              onCerrar={() => setSeleccionado(null)}
              onActualizado={actualizarPedidoLocal}
              puedeAgregarConsumos={
                tienePermiso("pedidos:crear") &&
                canalPermitido(obtenerCanalOperativo(seleccionado))
              }
              puedeCobrar={
                tienePermiso("pedidos:cobrar") &&
                canalPermitido(obtenerCanalOperativo(seleccionado))
              }
              puedeGestionarEstado={esAdmin}
            />
          )}
        </div>
      </div>

      <p className="sr-only" aria-live="polite">
        {seleccionado ? etiquetasEstado[seleccionado.estado] : "Ningún pedido seleccionado"}
      </p>

      {/* Drawer para Tomar Nuevo Pedido */}
      <DrawerCrearPedido
        abierto={drawerNuevoPedidoAbierto}
        onCerrar={() => setDrawerNuevoPedidoAbierto(false)}
        onPedidoCreado={refrescarPedidos}
        canalesDisponibles={canalesParaCrear}
      />
    </div>
  );
}