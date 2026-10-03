// src/pages/Administracion/DashboardAdmin.tsx
import { useEffect, useState } from "react";
import { Link } from "react-router";
import DrawerCrearPedido from "@/components/DrawerCrearPedido";
import {
  fechaLocalHoy,
  leerPedidosCache,
  obtenerPedidos,
  rangoDiaLocal,
} from "@/services/pedidosCache";
import {
  etiquetasEstado,
  formatoPrecio,
  obtenerCanalOperativo,
  type CanalOperativo,
  type Pedido,
} from "@/types/pedido";

function PlusIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="2" {...props}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M10 4v12m-6-6h12" />
    </svg>
  );
}

function RefreshIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.7" {...props}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M17.65 6.35A8 8 0 1 0 19 10M19 4v5h-5" />
    </svg>
  );
}

function estiloEstado(estado: Pedido["estado"]) {
  if (estado === "ENTREGADO") return "bg-emerald-50 text-emerald-700 dark:bg-emerald-950/30 dark:text-emerald-400";
  if (estado === "CANCELADO") return "bg-red-50 text-red-700 dark:bg-red-950/30 dark:text-red-400";
  if (estado === "EN_CAMINO") return "bg-amber-50 text-amber-700 dark:bg-amber-950/30 dark:text-amber-400";
  return "bg-brand-50 text-brand-700 dark:bg-brand-500/10 dark:text-brand-400";
}

export default function DashboardAdmin() {
  const [pedidos, setPedidos] = useState<Pedido[]>(() =>
    leerPedidosCache(rangoDiaLocal(fechaLocalHoy())) ?? []
  );
  const [cargando, setCargando] = useState(() =>
    leerPedidosCache(rangoDiaLocal(fechaLocalHoy())) === null
  );
  const [refrescando, setRefrescando] = useState(false);
  const [error, setError] = useState("");
  const [canalFiltro, setCanalFiltro] = useState<CanalOperativo | "TODOS">("TODOS");
  const [drawerPedidoAbierto, setDrawerPedidoAbierto] = useState(false);

  useEffect(() => {
    cargarDatos();
  }, []);

  async function cargarDatos(forzar = false) {
    if (forzar) setRefrescando(true);
    setError("");
    try {
      const datos = await obtenerPedidos(rangoDiaLocal(fechaLocalHoy()), forzar);
      setPedidos(datos);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error al actualizar");
    } finally {
      setCargando(false);
      setRefrescando(false);
    }
  }

  // Cálculos Operativos y Financieros
  const pedidosValidos = pedidos.filter((p) => p.estado !== "CANCELADO");

  // Totales financieros
  const cajaCobrada = pedidosValidos
    .filter((p) => p.pago?.estado === "pagado")
    .reduce((acc, p) => acc + Number(p.total), 0);

  const porCobrar = pedidosValidos
    .filter((p) => p.pago?.estado !== "pagado")
    .reduce((acc, p) => acc + Number(p.total), 0);

  // Conteo segmentado por los 3 canales
  const enSalonActivos = pedidosValidos.filter(
    (p) => obtenerCanalOperativo(p) === "SALON" && p.pago?.estado !== "pagado"
  ).length;

  const paraLlevarActivos = pedidosValidos.filter(
    (p) => obtenerCanalOperativo(p) === "PARA_LLEVAR" && p.estado !== "ENTREGADO"
  ).length;

  const deliveryActivos = pedidosValidos.filter(
    (p) => obtenerCanalOperativo(p) === "DELIVERY" && p.estado !== "ENTREGADO"
  ).length;

  // Filtrado de la lista de actividad
  const pedidosFiltrados = pedidos.filter((p) => {
    if (canalFiltro === "TODOS") return true;
    return obtenerCanalOperativo(p) === canalFiltro;
  });

  return (
    <div className="space-y-6">
      {/* Cabecera */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="text-sm text-gray-500 dark:text-gray-400">Resumen Ejecutivo</p>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Panel de Control</h1>
        </div>

        <div className="flex items-center gap-2.5">
          <button
            type="button"
            onClick={() => cargarDatos(true)}
            disabled={refrescando}
            title="Refrescar datos"
            className="flex size-10 items-center justify-center rounded-xl border border-gray-200 bg-white text-gray-600 hover:bg-gray-50 dark:border-gray-800 dark:bg-gray-800 dark:text-gray-300"
          >
            <RefreshIcon className={`size-4.5 ${refrescando ? "animate-spin text-brand-500" : ""}`} />
          </button>
          <button
            type="button"
            onClick={() => setDrawerPedidoAbierto(true)}
            className="flex items-center gap-2 rounded-xl bg-brand-500 px-4 py-2.5 text-sm font-bold text-white shadow-sm hover:bg-brand-600"
          >
            <PlusIcon className="size-4.5" />
            + Tomar Pedido
          </button>
        </div>
      </div>

      {error && <div className="rounded-xl bg-red-50 p-4 text-sm text-red-600 dark:bg-red-950/20">{error}</div>}

      {/* Métricas Financieras y de Operación */}
      <section className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-xs dark:border-gray-800 dark:bg-gray-900">
          <p className="text-xs font-bold uppercase tracking-wider text-gray-400">Caja Cobrada Hoy</p>
          <p className="mt-1 text-2xl font-black text-emerald-600 dark:text-emerald-400 tabular-nums">
            {cargando ? "..." : formatoPrecio(cajaCobrada)}
          </p>
          <p className="mt-1 text-xs text-gray-500">Ingresos liquidados</p>
        </div>

        <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-xs dark:border-gray-800 dark:bg-gray-900">
          <p className="text-xs font-bold uppercase tracking-wider text-gray-400">Cuentas por Cobrar</p>
          <p className="mt-1 text-2xl font-black text-amber-500 tabular-nums">
            {cargando ? "..." : formatoPrecio(porCobrar)}
          </p>
          <p className="mt-1 text-xs text-gray-500">Mesas consumiendo</p>
        </div>

        <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-xs dark:border-gray-800 dark:bg-gray-900">
          <p className="text-xs font-bold uppercase tracking-wider text-gray-400">Salón Activo</p>
          <p className="mt-1 text-2xl font-black text-blue-600 dark:text-blue-400 tabular-nums">
            {cargando ? "..." : `${enSalonActivos} Mesas`}
          </p>
          <p className="mt-1 text-xs text-gray-500">Comandas vivas en salón</p>
        </div>

        <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-xs dark:border-gray-800 dark:bg-gray-900">
          <p className="text-xs font-bold uppercase tracking-wider text-gray-400">Despacho Inmediato</p>
          <p className="mt-1 text-2xl font-black text-purple-600 dark:text-purple-400 tabular-nums">
            {cargando ? "..." : `${paraLlevarActivos + deliveryActivos} Pedidos`}
          </p>
          <p className="mt-1 text-xs text-gray-500">{paraLlevarActivos} Para Llevar · {deliveryActivos} Delivery</p>
        </div>
      </section>

      {/* Actividad Segmentada en los 3 Canales */}
      <section className="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-xs dark:border-gray-800 dark:bg-gray-900">
        <div className="flex flex-col gap-3 border-b border-gray-100 p-5 sm:flex-row sm:items-center sm:justify-between dark:border-gray-800">
          <div>
            <h2 className="text-base font-bold text-gray-900 dark:text-white">Pedidos Activos de Hoy</h2>
            <p className="text-xs text-gray-500">Clasificación por modalidad de atención</p>
          </div>

          {/* Pestañas de los 3 Canales */}
          <div className="flex gap-1.5 overflow-x-auto">
            {(["TODOS", "SALON", "PARA_LLEVAR", "DELIVERY"] as const).map((canal) => (
              <button
                key={canal}
                type="button"
                onClick={() => setCanalFiltro(canal)}
                className={`rounded-lg px-3 py-1.5 text-xs font-bold transition ${
                  canalFiltro === canal
                    ? "bg-brand-500 text-white shadow-xs"
                    : "bg-gray-100 text-gray-600 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-300"
                }`}
              >
                {canal === "TODOS"
                  ? `Todos (${pedidos.length})`
                  : canal === "SALON"
                  ? `En Salón (${enSalonActivos})`
                  : canal === "PARA_LLEVAR"
                  ? `Para Llevar (${paraLlevarActivos})`
                  : `Delivery (${deliveryActivos})`}
              </button>
            ))}
          </div>
        </div>

        {cargando ? (
          <p className="p-8 text-center text-sm text-gray-500">Cargando pedidos...</p>
        ) : pedidosFiltrados.length === 0 ? (
          <p className="p-8 text-center text-sm text-gray-500">No hay pedidos en este canal hoy.</p>
        ) : (
          <div className="divide-y divide-gray-100 dark:divide-gray-800">
            {pedidosFiltrados.slice(0, 10).map((pedido) => {
              const canalReal = obtenerCanalOperativo(pedido);
              return (
                <Link
                  key={pedido.id}
                  to="/admin/pedidos"
                  className="flex flex-wrap items-center justify-between gap-3 px-5 py-4 transition hover:bg-gray-50 dark:hover:bg-white/[0.02]"
                >
                  <div className="min-w-48">
                    <span className="font-bold text-gray-900 dark:text-white">{pedido.codigo}</span>
                    <p className="mt-0.5 text-xs text-gray-500 dark:text-gray-400">
                      {canalReal === "SALON"
                        ? `Mesa #${pedido.mesa?.numero ?? "-"}`
                        : canalReal === "PARA_LLEVAR"
                        ? `Para Llevar · Cliente: ${pedido.cliente?.nombre ?? "Mostrador"}`
                        : `Delivery · ${pedido.cliente?.nombre ?? "App"}`}
                    </p>
                  </div>

                  <div className="flex items-center gap-3">
                    <span
                      className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${
                        canalReal === "SALON"
                          ? "bg-blue-100 text-blue-700 dark:bg-blue-950/40 dark:text-blue-300"
                          : canalReal === "PARA_LLEVAR"
                          ? "bg-purple-100 text-purple-700 dark:bg-purple-950/40 dark:text-purple-300"
                          : "bg-amber-100 text-amber-700 dark:bg-amber-950/40 dark:text-amber-300"
                      }`}
                    >
                      {canalReal === "SALON" ? "Salón" : canalReal === "PARA_LLEVAR" ? "Para Llevar" : "Delivery"}
                    </span>

                    <span
                      className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${
                        pedido.pago?.estado === "pagado"
                          ? "bg-emerald-50 text-emerald-600 dark:bg-emerald-950/40 dark:text-emerald-400"
                          : "bg-amber-50 text-amber-600 dark:bg-amber-950/40 dark:text-amber-400"
                      }`}
                    >
                      {pedido.pago?.estado === "pagado" ? "Pagado" : "Pendiente"}
                    </span>

                    <span className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${estiloEstado(pedido.estado)}`}>
                      {etiquetasEstado[pedido.estado]}
                    </span>

                    <span className="text-sm font-bold tabular-nums text-gray-900 dark:text-white">
                      {formatoPrecio(pedido.total)}
                    </span>
                  </div>
                </Link>
              );
            })}
          </div>
        )}
      </section>

      <DrawerCrearPedido
        abierto={drawerPedidoAbierto}
        onCerrar={() => setDrawerPedidoAbierto(false)}
        onPedidoCreado={() => cargarDatos(true)}
        canalesDisponibles={["SALON", "PARA_LLEVAR"]}
      />
    </div>
  );
}