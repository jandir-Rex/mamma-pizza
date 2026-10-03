// src/pages/Administracion/RegistroPedidos.tsx
import { useEffect, useState } from "react";
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

type FiltroEstado = "GESTION" | "PENDIENTES" | "FINALIZADOS" | "CANCELADOS" | "ACTIVOS";

function esPedidoActivo(pedido: Pedido) {
  return pedido.estado !== "ENTREGADO" && pedido.estado !== "CANCELADO";
}

const PERMISO_POR_CANAL: Record<CanalOperativo, string> = {
  SALON: "pedidos:canal:SALON",
  PARA_LLEVAR: "pedidos:canal:PARA_LLEVAR",
  DELIVERY: "pedidos:canal:DELIVERY",
};

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
  const [drawerNuevoPedidoAbierto, setDrawerNuevoPedidoAbierto] = useState(false);
  const esAdmin = usuario?.rol === "ADMIN";
  const canalPermitido = (canal: CanalOperativo) =>
    esAdmin || tienePermiso(PERMISO_POR_CANAL[canal]);
  const canalesParaCrear = (["SALON", "PARA_LLEVAR"] as const).filter(canalPermitido);
  const pedidosAutorizados = pedidos.filter((pedido) =>
    canalPermitido(obtenerCanalOperativo(pedido))
  );

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

  // 2. Filtrar por Canal seleccionado
  const pedidosPorCanal = pedidosAutorizados.filter((p) => {
    if (canalFiltro === "TODOS") return true;
    return obtenerCanalOperativo(p) === canalFiltro;
  });

  // 3. Filtrar por búsqueda de texto
  const pedidosConBusqueda = pedidosPorCanal.filter((p) =>
    p.codigo.toLowerCase().includes(busqueda.trim().toLowerCase()) ||
    (p.cliente?.nombre && p.cliente.nombre.toLowerCase().includes(busqueda.trim().toLowerCase()))
  );

  // 4. Filtrar por Estado (Gestión, Pendientes, Finalizados)
  const pedidosVisibles = pedidosConBusqueda.filter((p) => {
    if (filtroEstado === "ACTIVOS") return esPedidoActivo(p);
    if (filtroEstado === "GESTION") return ["CONFIRMADO", "EN_PREPARACION", "EN_CAMINO"].includes(p.estado);
    if (filtroEstado === "PENDIENTES") return p.estado === "PENDIENTE_PAGO";
    if (filtroEstado === "FINALIZADOS") return p.estado === "ENTREGADO";
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

  return (
    <div className="space-y-5">
      {/* Encabezado Principal */}
      <div className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
        <div>
          <p className="text-sm text-gray-500 dark:text-gray-400">Operaciones en Vivo</p>
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
            {[
              { id: "ACTIVOS" as const, nombre: "Activos", cant: cantActivos },
              { id: "PENDIENTES" as const, nombre: "Pendientes de pago", cant: cantPendientes },
              { id: "GESTION" as const, nombre: "En gestión", cant: cantGestion },
              { id: "FINALIZADOS" as const, nombre: "Finalizados", cant: cantFinalizados },
              { id: "CANCELADOS" as const, nombre: "Cancelados", cant: cantCancelados },
            ].map((opcion) => (
              <button
                key={opcion.id}
                type="button"
                onClick={() => {
                  setFiltroEstado(opcion.id);
                  setSeleccionado(null);
                }}
                className={`inline-flex items-center gap-2 rounded-lg px-3 py-1.5 text-xs font-bold transition ${
                  filtroEstado === opcion.id
                    ? "bg-brand-50 text-brand-700 dark:bg-brand-500/10 dark:text-brand-400"
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
                No hay pedidos en este canal y filtro.
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