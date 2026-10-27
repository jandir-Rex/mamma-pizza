// src/components/FilaPedido.tsx
import {
  MAX_INTENTOS_CODIGO,
  formatoPrecio,
  obtenerEtiquetaEstado,
  type EstadoPedido,
  type Pedido,
} from "@/types/pedido";

function tiempoTranscurrido(fechaISO: string) {
  const minutos = Math.floor((Date.now() - new Date(fechaISO).getTime()) / 60000);
  if (minutos < 1) return "Recién";
  if (minutos < 60) return `Hace ${minutos} min`;
  return `Hace ${Math.floor(minutos / 60)} h`;
}

function estiloEstado(estado: EstadoPedido) {
  if (estado === "CONFIRMADO") return "bg-brand-50 text-brand-700 dark:bg-brand-500/10 dark:text-brand-400";
  if (estado === "EN_CAMINO") return "bg-warning-50 text-warning-700 dark:bg-warning-500/10 dark:text-warning-400";
  if (estado === "ENTREGADO") return "bg-success-50 text-success-700 dark:bg-success-500/10 dark:text-success-400";
  if (estado === "CANCELADO") return "bg-error-50 text-error-700 dark:bg-error-500/10 dark:text-error-400";
  return "bg-gray-100 text-gray-600 dark:bg-white/5 dark:text-gray-300";
}

export default function FilaPedido({
  pedido,
  seleccionado,
  onClick,
}: {
  pedido: Pedido;
  seleccionado: boolean;
  onClick: () => void;
}) {
  const pagado = pedido.pago?.estado === "pagado";
  const nombreClienteVisible = pedido.clienteNombre || pedido.cliente?.nombre || "Cliente";

  // --- Estado de reparto (solo delivery) ---
  const esDelivery = pedido.canal === "DELIVERY";
  const esperaRepartidor =
    esDelivery &&
    !pedido.repartidorId &&
    (pedido.estado === "CONFIRMADO" || pedido.estado === "EN_PREPARACION");
  const codigoBloqueado =
    esDelivery &&
    pedido.estado === "EN_CAMINO" &&
    (pedido.intentosCodigoFallidos ?? 0) >= MAX_INTENTOS_CODIGO;
  const nombreRepartidor =
    pedido.repartidor?.usuario?.nombre ??
    (pedido.repartidorId ? `Repartidor #${pedido.repartidorId}` : null);

  return (
    <button
      type="button"
      aria-pressed={seleccionado}
      onClick={onClick}
      className={`flex w-full flex-wrap items-center justify-between gap-x-5 gap-y-2 px-3 py-3 text-left transition ${
        seleccionado
          ? "bg-brand-50/70 dark:bg-brand-500/5"
          : "hover:bg-gray-50 dark:hover:bg-white/[0.03]"
      }`}
    >
      <div className="flex min-w-52 flex-1 items-center gap-3">
        <span
          className={`hidden h-8 w-1 shrink-0 rounded-full sm:block ${
            esperaRepartidor
              ? "animate-pulse bg-error-500"
              : pedido.estado === "CONFIRMADO"
              ? "bg-brand-500"
              : pedido.estado === "EN_PREPARACION"
                ? "bg-warning-500"
                : pedido.estado === "EN_CAMINO"
                  ? "bg-success-500"
                  : "bg-gray-300"
          }`}
        />
        <div className="min-w-0">
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-sm font-semibold text-gray-800 dark:text-white/90">
              {pedido.codigo}
            </span>
            <span className={`rounded-full px-2 py-0.5 text-[11px] font-medium ${estiloEstado(pedido.estado)}`}>
              {obtenerEtiquetaEstado(pedido)}
            </span>

            {esperaRepartidor && (
              <span className="animate-pulse rounded-full bg-error-50 px-2 py-0.5 text-[11px] font-bold text-error-700 dark:bg-error-500/10 dark:text-error-400">
                Sin repartidor
              </span>
            )}
            {codigoBloqueado && (
              <span className="rounded-full bg-error-50 px-2 py-0.5 text-[11px] font-bold text-error-700 dark:bg-error-500/10 dark:text-error-400">
                Código bloqueado
              </span>
            )}
          </div>

          <p className="mt-1 truncate text-xs text-gray-500 dark:text-gray-400">
            <span className="font-semibold text-gray-800 dark:text-gray-200">
              {nombreClienteVisible}
            </span>
            <span className="mx-1.5">·</span>
            {pedido.canal === "DELIVERY"
              ? "Delivery"
              : pedido.mesa?.numero
              ? `Salón · Mesa ${pedido.mesa.numero}`
              : "Para Llevar"}

            {esDelivery && nombreRepartidor && (
              <span className="ml-1.5 font-semibold text-gray-700 dark:text-gray-300">
                · Reparte: {nombreRepartidor}
              </span>
            )}

            {pedido.atendidoPor && (
              <span className="ml-1.5 font-bold text-brand-600 dark:text-brand-400">
                · Atiende: {pedido.atendidoPor.nombre} ({pedido.atendidoPor.rol === "ADMIN" ? "Mostrador" : "Mozo"})
              </span>
            )}
          </p>
        </div>
      </div>

      <div className="flex items-center gap-4 sm:gap-6">
        <span className="hidden text-xs text-gray-400 md:inline">
          {tiempoTranscurrido(pedido.createdAt)}
        </span>
        <span className="text-sm font-semibold tabular-nums text-gray-800 dark:text-white/90">
          {formatoPrecio(pedido.total)}
        </span>
        <span
          className={`hidden rounded-full px-2 py-0.5 text-[11px] font-medium sm:inline-flex ${
            pagado
              ? "bg-success-50 text-success-700 dark:bg-success-500/10 dark:text-success-400"
              : "bg-warning-50 text-warning-700 dark:bg-warning-500/10 dark:text-warning-400"
          }`}
        >
          {pagado ? "Pagado" : "Pago pendiente"}
        </span>
      </div>
      <span className="sr-only">
        {obtenerEtiquetaEstado(pedido)}, {tiempoTranscurrido(pedido.createdAt)}
        {esperaRepartidor ? ", sin repartidor asignado" : ""}
      </span>
    </button>
  );
}