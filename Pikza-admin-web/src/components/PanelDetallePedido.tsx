// src/components/PanelDetallePedido.tsx
import { useState } from "react";
import { apiRequest } from "@/services/api";
import { useAuth } from "@/context/AuthContext";
import {
  etiquetasEstado,
  formatoPrecio,
  obtenerEtiquetaEstado,
  type EstadoPedido,
  type Pedido,
  type VarianteInfo,
} from "@/types/pedido";
import { imprimirComandasPreparacion, imprimirTicketTermico } from "@/utils/impresionTicket";
import DrawerCobroMesa from "@/components/pedidos/DrawerCobroMesa";
import DrawerAgregarConsumo from "@/components/pedidos/DrawerAgregarConsumo";
import SeccionReparto from "@/components/pedidos/SeccionReparto";

// --- ICONOS VECTORIALES PROFESIONALES ---
function PrintIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6" {...props}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M5 7V3h10v4M5 15H3a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v4a2 2 0 0 1-2 2h-2M5 12h10v6H5v-6Z" />
    </svg>
  );
}

function PlusIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="2" {...props}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M10 4v12m-6-6h12" />
    </svg>
  );
}

const transicionesEstado: Partial<Record<EstadoPedido, EstadoPedido[]>> = {
  CONFIRMADO: ["EN_PREPARACION", "CANCELADO"],
  EN_PREPARACION: ["EN_CAMINO", "ENTREGADO", "CANCELADO"],
  EN_CAMINO: ["ENTREGADO", "CANCELADO"],
};

type Props = {
  pedido: Pedido | null;
  variantesMap: Record<number, VarianteInfo>;
  onCerrar: () => void;
  onActualizado: (pedido: Pedido) => void;
  soloLectura?: boolean;
  puedeAgregarConsumos?: boolean;
  puedeCobrar?: boolean;
  puedeGestionarEstado?: boolean;
};

export default function PanelDetallePedido({
  pedido,
  variantesMap,
  onCerrar,
  onActualizado,
  soloLectura = false,
  puedeAgregarConsumos = true,
  puedeCobrar = true,
  puedeGestionarEstado = true,
}: Props) {
  const { usuario } = useAuth();
  const [cargando, setCargando] = useState(false);
  const [error, setError] = useState("");
  const [drawerAgregarAbierto, setDrawerAgregarAbierto] = useState(false);
  const [drawerCobrarAbierto, setDrawerCobrarAbierto] = useState(false);
  const [historialExpandidoPara, setHistorialExpandidoPara] = useState<number | null>(null);

  // ADMIN, o PERSONALIZADO con reparto:gestion (el backend lo valida igual)
  const permisos = (usuario as { permisos?: string[] } | null)?.permisos ?? [];
  const puedeGestionarReparto =
    usuario?.rol === "ADMIN" ||
    (usuario?.rol === "PERSONALIZADO" && permisos.includes("reparto:gestion"));

  if (!pedido) {
    return (
      <aside className="hidden w-80 shrink-0 items-center justify-center border-l border-gray-200 px-6 text-center text-sm text-gray-400 lg:flex dark:border-gray-800">
        Selecciona un pedido para ver el detalle
      </aside>
    );
  }

  async function ejecutarCobro(metodo: "EFECTIVO" | "YAPE" | "TARJETA") {
    if (!pedido) return;
    setCargando(true);
    let pagoConfirmado: Pedido | null = null;
    try {
      pagoConfirmado = await apiRequest<Pedido>(`/pedidos/${pedido.id}/confirmar-pago`, {
        method: "PATCH",
        body: JSON.stringify({ metodo }),
      });
      if (pedido.canal === "DELIVERY") {
        onActualizado(pagoConfirmado);
      } else {
        const pedidoFinalizado = await apiRequest<Pedido>(`/pedidos/${pedido.id}/estado`, {
          method: "PATCH",
          body: JSON.stringify({ estado: "ENTREGADO" }),
        });
        onActualizado({ ...pagoConfirmado, ...pedidoFinalizado, pago: pagoConfirmado.pago });
      }

      setDrawerCobrarAbierto(false);
    } catch (err) {
      if (pagoConfirmado) onActualizado(pagoConfirmado);
      setError(err instanceof Error ? err.message : "Error al procesar el cobro");
    } finally {
      setCargando(false);
    }
  }

  // Ya no es optimista: al pasar a EN_CAMINO el backend genera el código de entrega
  // y necesitamos esa respuesta para mostrarlo.
  async function cambiarEstado(estado: EstadoPedido) {
    if (!pedido) return;
    setCargando(true);
    setError("");
    try {
      const actualizado = await apiRequest<Partial<Pedido>>(`/pedidos/${pedido.id}/estado`, {
        method: "PATCH",
        body: JSON.stringify({ estado }),
      });
      onActualizado({ ...pedido, ...actualizado });
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error al actualizar estado");
    } finally {
      setCargando(false);
    }
  }

  function forzarEntrega() {
    if (
      !window.confirm(
        "¿Marcar como entregado SIN el código del cliente? Quedará registrado como cierre manual.",
      )
    ) {
      return;
    }
    void cambiarEstado("ENTREGADO");
  }

  const transicionesDisponibles = (transicionesEstado[pedido.estado] ?? []).filter(
    (e) => e !== "EN_CAMINO" || pedido.canal === "DELIVERY"
  );

  // Prioridad: 1. Nombre ingresado en mostrador ("PruebaTest"), 2. Nombre de cuenta registrada, 3. Fallback
  const nombreClienteVisible = pedido.clienteNombre || pedido.cliente?.nombre || "Cliente en local";

  return (
    <aside className="flex w-full max-w-md flex-col overflow-y-auto border-l border-gray-200 bg-white p-6 shadow-xl lg:w-96 dark:border-gray-800 dark:bg-gray-900">
      {/* Cabecera */}
      <div className="mb-6 flex items-start justify-between border-b border-gray-100 pb-4 dark:border-gray-800">
        <div>
          <h2 className="text-xl font-bold text-gray-900 dark:text-white">{pedido.codigo}</h2>
          <p className="mt-1 text-sm font-medium text-gray-500 dark:text-gray-400">
            {pedido.canal === "DELIVERY"
              ? "Delivery"
              : pedido.mesa?.numero
              ? `Salón · Mesa ${pedido.mesa.numero}`
              : "Para Llevar"}
            <span className="mx-2">·</span>
              <span className="font-semibold text-brand-500">{obtenerEtiquetaEstado(pedido)}</span>
          </p>
        </div>

        <div className="flex items-center gap-1.5">
          <button
            type="button"
            onClick={() => imprimirTicketTermico(pedido, variantesMap, "PRECUENTA")}
            title="Imprimir Pre-cuenta"
            className="flex size-9 items-center justify-center rounded-lg border border-gray-200 text-gray-600 hover:bg-gray-100 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-gray-800"
          >
            <PrintIcon className="size-4.5" />
          </button>
          <button
            type="button"
            onClick={onCerrar}
            className="flex size-9 items-center justify-center rounded-lg text-gray-400 hover:bg-gray-100 lg:hidden"
          >
            ✕
          </button>
        </div>
      </div>

      {error && (
        <p role="alert" className="mb-4 rounded-lg bg-red-50 p-3 text-xs text-red-600 dark:bg-red-950/20">
          {error}
        </p>
      )}

      {/* Consumos en Comanda */}
      <section className="mb-6">
        <div className="mb-3 flex items-center justify-between">
          <h3 className="text-xs font-bold uppercase tracking-wider text-gray-400">
            Consumos en Comanda
          </h3>
          {puedeAgregarConsumos &&
            pedido.pago?.estado !== "pagado" &&
            pedido.estado !== "ENTREGADO" &&
            pedido.estado !== "CANCELADO" && (
              <button
                type="button"
                onClick={() => setDrawerAgregarAbierto(true)}
                className="flex items-center gap-1 text-xs font-bold text-brand-500 hover:underline"
              >
                <PlusIcon className="size-3.5" />
                Agregar producto
              </button>
            )}
        </div>

        <div className="space-y-3">
          {pedido.items.map((item) => {
            const variante = variantesMap[item.productoVarianteId];
            return (
              <div key={item.id} className="text-sm">
                <div className="flex justify-between gap-3 text-gray-800 dark:text-gray-200">
                  <span className="font-medium">
                    {item.cantidad}x{" "}
                    {variante
                      ? `${variante.nombre} (${variante.tamano})`
                      : `Producto #${item.productoVarianteId}`}
                  </span>
                  <span className="font-bold">
                    {formatoPrecio(Number(item.precioUnitario) * item.cantidad)}
                  </span>
                </div>
                {item.notas && <p className="mt-0.5 text-xs italic text-gray-400">“{item.notas}”</p>}
              </div>
            );
          })}
        </div>
      </section>

      {/* Total Acumulado */}
      <div className="mb-6 flex justify-between border-t border-gray-100 pt-4 text-base font-bold text-gray-900 dark:border-gray-800 dark:text-white">
        <span>Cuenta Total</span>
        <span className="text-2xl font-black text-brand-500">{formatoPrecio(pedido.total)}</span>
      </div>

      {/* Estado del Pago */}
      <section className="mb-5 rounded-lg bg-gray-50 p-3.5 dark:bg-gray-800/40">
        <h3 className="mb-1 text-xs font-bold uppercase tracking-wider text-gray-400">Estado de Cuenta</h3>
        <p className="text-sm font-semibold text-gray-800 dark:text-gray-200">
          {pedido.pago?.metodo ?? "EFECTIVO"} ·{" "}
          <span
            className={
              pedido.pago?.estado === "pagado"
                ? "text-emerald-500 font-bold"
                : "text-amber-500 font-bold"
            }
          >
            {pedido.pago?.estado === "pagado" ? "Cuenta Pagada" : "Comanda Abierta (Por Pagar)"}
          </span>
        </p>
      </section>

      {/* Atendido Por (Staff / Mozo / Mostrador) */}
      {pedido.atendidoPor && (
        <section className="mb-5 rounded-lg bg-gray-50 p-3.5 dark:bg-gray-800/40">
          <h3 className="mb-1 text-xs font-bold uppercase tracking-wider text-gray-400">Atendido Por</h3>
          <p className="text-sm font-semibold text-gray-800 dark:text-gray-200">
            {pedido.atendidoPor.nombre}
            <span className="ml-2 rounded bg-brand-50 px-2 py-0.5 text-xs text-brand-600 dark:bg-brand-500/10 dark:text-brand-400">
              {pedido.atendidoPor.rol === "ADMIN"
                ? "Mostrador / Admin"
                : pedido.atendidoPor.rol === "PERSONALIZADO"
                ? "Personal configurable"
                : "Mozo"}
            </span>
          </p>
        </section>
      )}

      {pedido.historialAtencion && pedido.historialAtencion.length > 0 && (
        <section className="mb-5 rounded-lg border border-gray-100 p-3.5 dark:border-gray-800">
          <div className="mb-2 flex items-center justify-between gap-2">
            <h3 className="text-xs font-bold uppercase tracking-wider text-gray-400">
              Historial de atención
            </h3>
            {pedido.historialAtencion.length > 1 && (
              <button
                type="button"
                aria-expanded={historialExpandidoPara === pedido.id}
                onClick={() =>
                  setHistorialExpandidoPara((actual) =>
                    actual === pedido.id ? null : pedido.id,
                  )
                }
                className="text-[11px] font-semibold text-brand-600 hover:underline dark:text-brand-400"
              >
                {historialExpandidoPara === pedido.id
                  ? "Compactar historial"
                  : `Expandir historial (${pedido.historialAtencion.length})`}
              </button>
            )}
          </div>
          <ol className="space-y-2">
            {(historialExpandidoPara === pedido.id
              ? pedido.historialAtencion
              : pedido.historialAtencion.slice(-1)
            ).map((evento) => (
              <li key={evento.id} className="text-xs text-gray-600 dark:text-gray-300">
                <span className="font-semibold text-gray-800 dark:text-gray-100">
                  {evento.usuarioNombre}
                </span>
                <span className="ml-1 text-gray-400">
                  ({evento.usuarioRol === "ADMIN"
                    ? "Administrador"
                    : evento.usuarioRol === "PERSONALIZADO"
                    ? "Personal configurable"
                    : "Mozo"})
                </span>
                {" · "}
                {evento.accion === "REGISTRO"
                  ? "registró el pedido"
                  : evento.accion === "CONTINUACION"
                    ? "continuó la comanda"
                    : "finalizó el pedido"}
                <time className="mt-0.5 block text-[11px] text-gray-400">
                  {new Date(evento.createdAt).toLocaleString("es-PE")}
                </time>
              </li>
            ))}
          </ol>
        </section>
      )}

      {/* Cliente Real */}
      <section className="mb-5">
        <h3 className="mb-1 text-xs font-bold uppercase tracking-wider text-gray-400">Cliente</h3>
        <p className="text-sm font-semibold text-gray-800 dark:text-gray-200">{nombreClienteVisible}</p>
        {pedido.cliente?.telefono && !pedido.clienteNombre && (
          <p className="text-xs text-gray-400">{pedido.cliente.telefono}</p>
        )}
      </section>

      {/* Reparto: asignación, top 3 sugeridos, liberar y código de entrega */}
      <SeccionReparto
        pedido={pedido}
        puedeGestionar={puedeGestionarReparto}
        soloLectura={soloLectura}
        onActualizado={onActualizado}
      />

      {/* Botones de Operación */}
      {!soloLectura && (
        <div className="mt-auto space-y-2.5 border-t border-gray-100 pt-5 dark:border-gray-800">
          {/* Si aún no está pagado: Botón de Cobro Final */}
          {puedeCobrar && pedido.pago?.estado !== "pagado" && (
            <button
              type="button"
              disabled={cargando}
              onClick={() => setDrawerCobrarAbierto(true)}
              className="w-full rounded-xl bg-emerald-600 py-3 text-sm font-bold text-white hover:bg-emerald-700 disabled:opacity-50"
            >
              {pedido.canal === "DELIVERY" ? "Registrar pago" : "Cobrar y Cerrar Cuenta"}
            </button>
          )}

          <button
            type="button"
            disabled={pedido.items.length === 0}
            onClick={() => imprimirComandasPreparacion(pedido, variantesMap)}
            className="w-full rounded-xl border border-gray-300 py-2.5 text-xs font-bold text-gray-700 hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-50 dark:border-gray-700 dark:text-gray-300"
          >
            Imprimir tickets de preparación
          </button>

          {puedeGestionarEstado &&
            transicionesDisponibles
              .filter((e) => e !== "CANCELADO" && e !== "ENTREGADO")
              .map((estado) => {
                // Ninguna pizza sale a la calle sin repartidor (el backend también lo bloquea)
                const faltaRepartidor = estado === "EN_CAMINO" && !pedido.repartidorId;
                return (
                  <div key={estado}>
                    <button
                      type="button"
                      disabled={cargando || faltaRepartidor}
                      onClick={() => cambiarEstado(estado)}
                      className="w-full rounded-xl bg-brand-500 py-2.5 text-sm font-bold text-white hover:bg-brand-600 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                      Marcar {etiquetasEstado[estado]}
                    </button>
                    {faltaRepartidor && (
                      <p className="mt-1 text-center text-[11px] font-semibold text-error-600 dark:text-error-400">
                        Asigna un repartidor para poder despacharlo
                      </p>
                    )}
                  </div>
                );
              })}

          {puedeGestionarEstado && transicionesDisponibles.includes("CANCELADO") && (
            <button
              type="button"
              disabled={cargando}
              onClick={() => cambiarEstado("CANCELADO")}
              className="w-full rounded-xl border border-red-200 py-2.5 text-xs font-bold text-red-600 hover:bg-red-50 dark:border-red-900/30 dark:text-red-400"
            >
              Anular / Cancelar Pedido
            </button>
          )}

          {puedeCobrar &&
            pedido.canal !== "DELIVERY" &&
            pedido.pago?.estado === "pagado" &&
            pedido.estado !== "ENTREGADO" &&
            pedido.estado !== "CANCELADO" && (
              <button
                type="button"
                disabled={cargando}
                onClick={() => cambiarEstado("ENTREGADO")}
                className="w-full rounded-xl bg-emerald-600 py-2.5 text-sm font-bold text-white hover:bg-emerald-700 disabled:opacity-50"
              >
                Finalizar pedido cobrado
              </button>
            )}

          {/* Salida de emergencia: el flujo normal es que el repartidor use el código */}
          {puedeGestionarEstado &&
            pedido.canal === "DELIVERY" &&
            pedido.estado === "EN_CAMINO" && (
              <button
                type="button"
                disabled={cargando}
                onClick={forzarEntrega}
                className="w-full rounded-xl border border-amber-300 py-2.5 text-xs font-bold text-amber-700 hover:bg-amber-50 disabled:opacity-50 dark:border-amber-500/30 dark:text-amber-400 dark:hover:bg-amber-500/10"
              >
                Forzar entrega (sin código)
              </button>
            )}
        </div>
      )}

      {/* Subcomponentes Integrados */}
      <DrawerAgregarConsumo
        abierto={drawerAgregarAbierto}
        pedido={pedido}
        onCerrar={() => setDrawerAgregarAbierto(false)}
        onActualizado={onActualizado}
      />

      <DrawerCobroMesa
        abierto={drawerCobrarAbierto}
        pedido={pedido}
        cargando={cargando}
        onCerrar={() => setDrawerCobrarAbierto(false)}
        onConfirmar={ejecutarCobro}
      />
    </aside>
  );
}