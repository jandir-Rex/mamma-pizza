import { useEffect, useState } from "react";
import { apiRequest } from "@/services/api";
import { etiquetasEstado, formatoPrecio, type Pedido } from "@/types/pedido";

// Helper para colores según estado
const ESTADO_ESTILOS: Record<string, string> = {
  PENDIENTE: "bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-400 border-amber-200 dark:border-amber-800",
  EN_PREPARACION: "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400 border-blue-200 dark:border-blue-800",
  EN_CAMINO: "bg-indigo-100 text-indigo-800 dark:bg-indigo-900/30 dark:text-indigo-400 border-indigo-200 dark:border-indigo-800",
  ENTREGADO: "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-400 border-emerald-200 dark:border-emerald-800",
  CANCELADO: "bg-rose-100 text-rose-800 dark:bg-rose-900/30 dark:text-rose-400 border-rose-200 dark:border-rose-800",
};

export default function DeliveryDashboard() {
  const [pedidos, setPedidos] = useState<Pedido[]>([]);
  const [cargando, setCargando] = useState(true);
  const [actualizandoId, setActualizandoId] = useState<number | null>(null);
  const [error, setError] = useState("");
  const [recarga, setRecarga] = useState(0);

  // Estado para el filtro de fecha / DatePicker
  const [fechaSeleccionada, setFechaSeleccionada] = useState<number>(new Date().getDate());

  useEffect(() => {
    let activo = true;

    apiRequest<Pedido[]>("/pedidos/repartidor/mis-entregas")
      .then((datos) => {
        if (activo) setPedidos(datos);
      })
      .catch((err: unknown) => {
        if (activo) setError(err instanceof Error ? err.message : "No se pudieron cargar las entregas");
      })
      .finally(() => {
        if (activo) setCargando(false);
      });

    return () => {
      activo = false;
    };
  }, [recarga]);

  async function actualizarEstado(pedido: Pedido, estado: "EN_CAMINO" | "ENTREGADO") {
    setActualizandoId(pedido.id);
    setError("");

    try {
      const actualizado = await apiRequest<Partial<Pedido>>(
        `/pedidos/${pedido.id}/estado`,
        { method: "PATCH", body: JSON.stringify({ estado }) },
      );
      setPedidos((actuales) =>
        actuales.map((item) =>
          item.id === pedido.id ? { ...item, ...actualizado } : item,
        ),
      );
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudo actualizar la entrega");
    } finally {
      setActualizandoId(null);
    }
  }

  // Métricas para el Mini-Bar Header
  const pendientes = pedidos.filter((p) => p.estado === "EN_PREPARACION").length;
  const enCamino = pedidos.filter((p) => p.estado === "EN_CAMINO").length;
  const entregados = pedidos.filter((p) => p.estado === "ENTREGADO").length;

  return (
    <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6">
      {/* HEADER DE TÍTULO & ACCIONES */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <span className="text-xs font-bold uppercase tracking-wider text-brand-500">
            Módulo Repartidor
          </span>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white sm:text-3xl">
            Mis Entregas
          </h1>
        </div>

        <button
          type="button"
          onClick={() => {
            setCargando(true);
            setRecarga((valor) => valor + 1);
          }}
          className="inline-flex items-center justify-center gap-2 rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-sm font-semibold text-gray-700 shadow-xs hover:bg-gray-50 dark:border-gray-800 dark:bg-gray-900 dark:text-gray-200 dark:hover:bg-gray-800/80 transition-all"
        >
          <svg className={`h-4 w-4 ${cargando ? "animate-spin" : ""}`} fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          {cargando ? "Actualizando..." : "Refrescar Lista"}
        </button>
      </div>

      {/* FILTRO DE FECHAS / DATEPICKER DIA SELECCIONADO */}
      <div className="flex items-center gap-2 overflow-x-auto rounded-2xl border border-gray-200 bg-white p-3 shadow-xs dark:border-gray-800 dark:bg-gray-900">
        <span className="mr-2 text-xs font-semibold text-gray-500 dark:text-gray-400">Día:</span>
        {Array.from({ length: 7 }, (_, i) => i + 15).map((numDia) => {
          const esSeleccionado = fechaSeleccionada === numDia;
          return (
            <button
              key={numDia}
              type="button"
              onClick={() => setFechaSeleccionada(numDia)}
              className={`flex h-9 w-9 items-center justify-center rounded-lg text-sm transition-all ${
                esSeleccionado
                  ? "bg-slate-800 text-white dark:bg-sky-500/30 dark:text-sky-300 font-bold border border-transparent dark:border-sky-500/40 shadow-xs"
                  : "text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-white/5"
              }`}
            >
              {numDia}
            </button>
          );
        })}
      </div>

      {/* MINI-BAR HEADER (Resumen métrico en tarjetas horizontales) */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <div className="flex items-center gap-4 rounded-2xl border border-gray-200 bg-white p-4 shadow-xs dark:border-gray-800 dark:bg-gray-900">
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-blue-50 text-blue-600 dark:bg-blue-950/50 dark:text-blue-400">
            <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <div>
            <p className="text-xs font-medium text-gray-500 dark:text-gray-400">Por Recoger / Listos</p>
            <p className="text-2xl font-bold text-gray-900 dark:text-white">{pendientes}</p>
          </div>
        </div>

        <div className="flex items-center gap-4 rounded-2xl border border-gray-200 bg-white p-4 shadow-xs dark:border-gray-800 dark:bg-gray-900">
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-indigo-50 text-indigo-600 dark:bg-indigo-950/50 dark:text-indigo-400">
            <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
            </svg>
          </div>
          <div>
            <p className="text-xs font-medium text-gray-500 dark:text-gray-400">En Camino</p>
            <p className="text-2xl font-bold text-gray-900 dark:text-white">{enCamino}</p>
          </div>
        </div>

        <div className="flex items-center gap-4 rounded-2xl border border-gray-200 bg-white p-4 shadow-xs dark:border-gray-800 dark:bg-gray-900">
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-50 text-emerald-600 dark:bg-emerald-950/50 dark:text-emerald-400">
            <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <div>
            <p className="text-xs font-medium text-gray-500 dark:text-gray-400">Entregados Hoy</p>
            <p className="text-2xl font-bold text-gray-900 dark:text-white">{entregados}</p>
          </div>
        </div>
      </div>

      {/* MENSAJE DE ERROR */}
      {error && (
        <div role="alert" className="flex items-center gap-3 rounded-xl border border-rose-200 bg-rose-50 p-4 text-sm text-rose-800 dark:border-rose-900/50 dark:bg-rose-950/30 dark:text-rose-400">
          <svg className="h-5 w-5 shrink-0 text-rose-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <span>{error}</span>
        </div>
      )}

      {/* CONTENIDO PRINCIPAL */}
      {cargando ? (
        <div className="flex flex-col items-center justify-center rounded-2xl border border-gray-200 bg-white p-12 dark:border-gray-800 dark:bg-gray-900">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-brand-500 border-t-transparent" />
          <p className="mt-4 text-sm font-medium text-gray-500 dark:text-gray-400">Cargando la ruta de entregas...</p>
        </div>
      ) : pedidos.length === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-gray-300 bg-white p-12 text-center dark:border-gray-800 dark:bg-gray-900">
          <div className="flex h-16 w-16 items-center justify-center rounded-full bg-gray-100 dark:bg-gray-800">
            <svg className="h-8 w-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
            </svg>
          </div>
          <h3 className="mt-4 text-base font-semibold text-gray-900 dark:text-white">Sin entregas asignadas</h3>
          <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">Todo al día por aquí. Cuando tengas una pizza que entregar aparecerá en esta sección.</p>
        </div>
      ) : (
        <section className="space-y-4">
          {pedidos.map((pedido) => {
            const siguiente =
              pedido.estado === "EN_PREPARACION"
                ? "EN_CAMINO"
                : pedido.estado === "EN_CAMINO"
                ? "ENTREGADO"
                : null;

            const esLlamable = Boolean(pedido.cliente?.telefono);

            return (
              <article
                key={pedido.id}
                className="overflow-hidden rounded-2xl border border-gray-200 bg-white transition-all hover:shadow-md dark:border-gray-800 dark:bg-gray-900"
              >
                <div className="flex flex-col gap-4 p-5 md:flex-row md:items-center md:justify-between">
                  {/* Info Izquierda */}
                  <div className="space-y-3 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="text-lg font-bold text-gray-900 dark:text-white">
                        #{pedido.codigo}
                      </span>
                      <span className={`inline-flex items-center rounded-md border px-2.5 py-0.5 text-xs font-semibold ${ESTADO_ESTILOS[pedido.estado] || "bg-gray-100 text-gray-800"}`}>
                        {etiquetasEstado[pedido.estado] || pedido.estado}
                      </span>
                    </div>

                    <div className="grid grid-cols-1 gap-1.5 text-sm text-gray-600 dark:text-gray-300 sm:grid-cols-2">
                      <div className="flex items-center gap-2">
                        <svg className="h-4 w-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                        </svg>
                        <span className="font-medium text-gray-900 dark:text-white">
                          {pedido.cliente?.nombre ?? "Cliente sin nombre"}
                        </span>
                      </div>

                      {esLlamable && (
                        <a
                          href={`tel:${pedido.cliente?.telefono}`}
                          className="inline-flex items-center gap-1.5 font-medium text-brand-600 hover:text-brand-700 dark:text-brand-400 dark:hover:text-brand-300"
                        >
                          <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                          </svg>
                          {pedido.cliente?.telefono}
                        </a>
                      )}
                    </div>
                  </div>

                  {/* Info Derecha & Botón */}
                  <div className="flex flex-wrap items-center justify-between gap-4 border-t border-gray-100 pt-4 dark:border-gray-800 md:border-t-0 md:pt-0">
                    <div className="text-right">
                      <p className="text-xs text-gray-500 dark:text-gray-400">Monto total</p>
                      <p className="text-xl font-extrabold text-gray-900 dark:text-white">
                        {formatoPrecio(pedido.total)}
                      </p>
                    </div>

                    {siguiente && (
                      <button
                        type="button"
                        disabled={actualizandoId === pedido.id}
                        onClick={() => actualizarEstado(pedido, siguiente)}
                        className={`inline-flex items-center justify-center gap-2 rounded-xl px-5 py-2.5 text-sm font-semibold text-white shadow-xs transition-all disabled:opacity-50 ${
                          siguiente === "EN_CAMINO"
                            ? "bg-indigo-600 hover:bg-indigo-700 focus:ring-4 focus:ring-indigo-100 dark:focus:ring-indigo-900/50"
                            : "bg-emerald-600 hover:bg-emerald-700 focus:ring-4 focus:ring-emerald-100 dark:focus:ring-emerald-900/50"
                        }`}
                      >
                        {actualizandoId === pedido.id ? (
                          <>
                            <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
                            <span>Guardando...</span>
                          </>
                        ) : siguiente === "EN_CAMINO" ? (
                          <>
                            <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                            </svg>
                            <span>Iniciar entrega</span>
                          </>
                        ) : (
                          <>
                            <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                            </svg>
                            <span>Marcar como entregado</span>
                          </>
                        )}
                      </button>
                    )}
                  </div>
                </div>
              </article>
            );
          })}
        </section>
      )}
    </div>
  );
}