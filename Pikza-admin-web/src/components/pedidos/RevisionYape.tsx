// src/components/pedidos/RevisionYape.tsx
import { useEffect, useState } from "react";
import { API_BASE_URL, apiRequest } from "@/services/api";
import { formatoPrecio, type Pedido } from "@/types/pedido";

type Props = {
  pedido: Pedido;
  /** Quien puede aprobar/rechazar (permiso de cobro) */
  puedeRevisar: boolean;
  onActualizado: (pedido: Pedido) => void;
};

const TITULO = "mb-2 text-xs font-bold uppercase tracking-wider text-gray-400";

export default function RevisionYape({ pedido, puedeRevisar, onActualizado }: Props) {
  const pago = pedido.pago;
  const estado = pago?.comprobanteEstado ?? "SIN_COMPROBANTE";
  const tieneImagen = estado !== "SIN_COMPROBANTE";

  const [src, setSrc] = useState<string | null>(null);
  const [ampliada, setAmpliada] = useState(false);
  const [rechazando, setRechazando] = useState(false);
  const [motivo, setMotivo] = useState("");
  const [accion, setAccion] = useState<"aprobar" | "rechazar" | null>(null);
  const [error, setError] = useState("");

  // La imagen es privada: se pide con el token y se muestra como blob
  useEffect(() => {
    if (!tieneImagen) {
      setSrc(null);
      return;
    }
    let activo = true;
    let url: string | null = null;
    fetch(`${API_BASE_URL}/pedidos/${pedido.id}/comprobante`, {
      headers: { Authorization: `Bearer ${localStorage.getItem("token")}` },
    })
      .then(async (r) => {
        if (!r.ok) throw new Error();
        url = URL.createObjectURL(await r.blob());
        if (activo) setSrc(url);
      })
      .catch(() => {
        if (activo) setError("No se pudo cargar la captura");
      });
    return () => {
      activo = false;
      if (url) URL.revokeObjectURL(url);
    };
  }, [pedido.id, tieneImagen, pago?.comprobanteSubidoEn]);

  if (pago?.metodo !== "YAPE") return null;
  // Yape cobrado por el mozo/cajero en local: no lleva captura
  if (pedido.atendidoPorId && !tieneImagen) return null;

  const enRevision = estado === "EN_REVISION" && pedido.estado === "PENDIENTE_PAGO";
  const nombreCliente = pedido.clienteNombre || pedido.cliente?.nombre || "—";

  async function aprobar() {
    setAccion("aprobar");
    setError("");
    try {
      const r = await apiRequest<Partial<Pedido>>(`/pedidos/${pedido.id}/confirmar-pago`, {
        method: "PATCH",
        body: JSON.stringify({ metodo: "YAPE" }),
      });
      onActualizado({ ...pedido, ...r } as Pedido);
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudo aprobar el pago");
    } finally {
      setAccion(null);
    }
  }

  async function rechazar() {
    setAccion("rechazar");
    setError("");
    try {
      const r = await apiRequest<Partial<Pedido>>(`/pedidos/${pedido.id}/rechazar-comprobante`, {
        method: "PATCH",
        body: JSON.stringify({ motivo }),
      });
      onActualizado({ ...pedido, ...r } as Pedido);
      setRechazando(false);
      setMotivo("");
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudo rechazar el comprobante");
    } finally {
      setAccion(null);
    }
  }

  return (
    <section className="mb-5 rounded-lg border border-purple-200 bg-purple-50/60 p-3.5 dark:border-purple-500/20 dark:bg-purple-500/5">
      <h3 className={TITULO}>Verificación de Yape</h3>

      {error && (
        <p role="alert" className="mb-2 rounded-lg bg-red-50 p-2.5 text-xs text-red-600 dark:bg-red-950/20">
          {error}
        </p>
      )}

      {estado === "SIN_COMPROBANTE" && (
        <p className="text-xs font-semibold text-amber-600 dark:text-amber-400">
          Esperando que el cliente suba la captura de su Yape.
        </p>
      )}

      {tieneImagen && (
        <>
          <button
            type="button"
            onClick={() => src && setAmpliada(true)}
            className="block w-full overflow-hidden rounded-lg border border-gray-200 bg-white dark:border-gray-700"
          >
            {src ? (
              <img src={src} alt="Captura del Yape" className="max-h-72 w-full object-contain" />
            ) : (
              <div className="p-6 text-center text-xs text-gray-400">Cargando captura...</div>
            )}
          </button>
          <p className="mt-1 text-center text-[11px] text-gray-400">Toca la imagen para ampliarla</p>

          <dl className="mt-3 space-y-1 text-xs text-gray-600 dark:text-gray-300">
            <div className="flex justify-between gap-3">
              <dt>Monto a verificar</dt>
              <dd className="font-black text-gray-900 dark:text-white">{formatoPrecio(pedido.total)}</dd>
            </div>
            <div className="flex justify-between gap-3">
              <dt>Yapeó (según el cliente)</dt>
              <dd className="font-bold text-gray-900 dark:text-white">{pago?.yapeNombre ?? "—"}</dd>
            </div>
            <div className="flex justify-between gap-3">
              <dt>Cuenta del cliente</dt>
              <dd>{nombreCliente}</dd>
            </div>
            {pago?.comprobanteSubidoEn && (
              <div className="flex justify-between gap-3">
                <dt>Enviado</dt>
                <dd>{new Date(pago.comprobanteSubidoEn).toLocaleString("es-PE")}</dd>
              </div>
            )}
          </dl>
        </>
      )}

      {estado === "APROBADO" && (
        <p className="mt-2 text-xs font-bold text-emerald-600 dark:text-emerald-400">Comprobante aprobado</p>
      )}

      {estado === "RECHAZADO" && (
        <p className="mt-2 text-xs font-bold text-red-600 dark:text-red-400">
          Rechazado: {pago?.comprobanteMotivo}. Esperando una nueva captura del cliente.
        </p>
      )}

      {enRevision && puedeRevisar && (
        <div className="mt-3 space-y-2">
          {rechazando ? (
            <>
              <textarea
                value={motivo}
                onChange={(e) => setMotivo(e.target.value)}
                rows={2}
                maxLength={200}
                placeholder="Motivo (ej.: el monto no coincide, captura ilegible)"
                className="w-full rounded-lg border border-gray-300 bg-white p-2 text-xs dark:border-gray-700 dark:bg-gray-900 dark:text-white"
              />
              <div className="flex gap-2">
                <button
                  type="button"
                  disabled={accion !== null || motivo.trim().length < 3}
                  onClick={rechazar}
                  className="flex-1 rounded-lg bg-red-600 py-2 text-xs font-bold text-white hover:bg-red-700 disabled:opacity-50"
                >
                  {accion === "rechazar" ? "Rechazando..." : "Confirmar rechazo"}
                </button>
                <button
                  type="button"
                  onClick={() => setRechazando(false)}
                  className="rounded-lg border border-gray-300 px-3 py-2 text-xs font-semibold text-gray-600 dark:border-gray-700 dark:text-gray-300"
                >
                  Volver
                </button>
              </div>
            </>
          ) : (
            <div className="flex gap-2">
              <button
                type="button"
                disabled={accion !== null}
                onClick={aprobar}
                className="flex-1 rounded-lg bg-emerald-600 py-2.5 text-xs font-bold text-white hover:bg-emerald-700 disabled:opacity-50"
              >
                {accion === "aprobar" ? "Aprobando..." : "Aprobar pago"}
              </button>
              <button
                type="button"
                disabled={accion !== null}
                onClick={() => setRechazando(true)}
                className="flex-1 rounded-lg border border-red-300 py-2.5 text-xs font-bold text-red-600 hover:bg-red-50 disabled:opacity-50 dark:border-red-500/30 dark:text-red-400"
              >
                Rechazar
              </button>
            </div>
          )}
        </div>
      )}

      {ampliada && src && (
        <div
          onClick={() => setAmpliada(false)}
          className="fixed inset-0 z-[60] flex cursor-zoom-out items-center justify-center bg-black/85 p-4"
        >
          <img src={src} alt="Captura del Yape ampliada" className="max-h-full max-w-full object-contain" />
        </div>
      )}
    </section>
  );
}