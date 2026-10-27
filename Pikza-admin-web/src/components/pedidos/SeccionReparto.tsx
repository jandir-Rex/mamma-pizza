// src/components/pedidos/SeccionReparto.tsx
import { useEffect, useState } from "react";
import { apiRequest } from "@/services/api";
import {
  MAX_INTENTOS_CODIGO,
  type CandidatoRepartidor,
  type Pedido,
  type SugerenciaRepartidores,
} from "@/types/pedido";

const ESTADOS_ASIGNABLES = ["CONFIRMADO", "EN_PREPARACION"];

const TITULO = "mb-1 text-xs font-bold uppercase tracking-wider text-gray-400";

type Props = {
  pedido: Pedido;
  /** ADMIN, o PERSONALIZADO con el permiso reparto:gestion */
  puedeGestionar: boolean;
  soloLectura?: boolean;
  onActualizado: (pedido: Pedido) => void;
};

export default function SeccionReparto({
  pedido,
  puedeGestionar,
  soloLectura = false,
  onActualizado,
}: Props) {
  const [sugerencia, setSugerencia] = useState<SugerenciaRepartidores | null>(null);
  const [cargandoSugerencia, setCargandoSugerencia] = useState(false);
  const [accion, setAccion] = useState<string | null>(null);
  const [error, setError] = useState("");
  const [recarga, setRecarga] = useState(0);

  const gestiona = puedeGestionar && !soloLectura;
  const asignable = ESTADOS_ASIGNABLES.includes(pedido.estado);
  const necesitaAsignacion = gestiona && asignable && !pedido.repartidorId;

  // Carga el top 3 cuando el pedido está "al aire"
  useEffect(() => {
    setError("");
    if (!necesitaAsignacion) {
      setSugerencia(null);
      return;
    }

    let activo = true;
    setCargandoSugerencia(true);
    apiRequest<SugerenciaRepartidores>(`/pedidos/${pedido.id}/sugerir-repartidores`)
      .then((datos) => {
        if (activo) setSugerencia(datos);
      })
      .catch((err: unknown) => {
        if (activo) {
          setError(err instanceof Error ? err.message : "No se pudieron cargar las sugerencias");
        }
      })
      .finally(() => {
        if (activo) setCargandoSugerencia(false);
      });

    return () => {
      activo = false;
    };
  }, [pedido.id, necesitaAsignacion, recarga]);

  async function asignar(candidato: CandidatoRepartidor) {
    setAccion(`asignar-${candidato.repartidorId}`);
    setError("");
    try {
      const respuesta = await apiRequest<Partial<Pedido>>(
        `/pedidos/${pedido.id}/asignar-repartidor`,
        {
          method: "PATCH",
          body: JSON.stringify({ repartidorId: candidato.repartidorId }),
        },
      );
      onActualizado({
        ...pedido,
        ...respuesta,
        // Por si el backend no devuelve la relación, usamos el nombre que ya conocemos
        repartidor: respuesta.repartidor ?? {
          id: candidato.repartidorId,
          usuario: { nombre: candidato.nombre },
        },
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudo asignar el repartidor");
      setRecarga((v) => v + 1); // cupos pudieron cambiar: volvemos a pedir el top 3
    } finally {
      setAccion(null);
    }
  }

  async function liberar() {
    if (
      !window.confirm(
        "¿Soltar este pedido? Volverá al pool y se buscará otro repartidor.",
      )
    ) {
      return;
    }
    setAccion("liberar");
    setError("");
    try {
      const respuesta = await apiRequest<Partial<Pedido>>(
        `/pedidos/${pedido.id}/liberar-repartidor`,
        { method: "PATCH" },
      );
      onActualizado({ ...pedido, ...respuesta, repartidorId: null, repartidor: null });
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudo liberar el pedido");
    } finally {
      setAccion(null);
    }
  }

  async function resetearCodigo(regenerar: boolean) {
    setAccion(regenerar ? "codigo-nuevo" : "reiniciar");
    setError("");
    try {
      const respuesta = await apiRequest<Partial<Pedido>>(
        `/pedidos/${pedido.id}/resetear-codigo`,
        { method: "PATCH", body: JSON.stringify({ regenerar }) },
      );
      onActualizado({ ...pedido, ...respuesta });
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudo reiniciar el código");
    } finally {
      setAccion(null);
    }
  }

  // ---------- Render ----------
  if (pedido.canal !== "DELIVERY" || pedido.estado === "CANCELADO") return null;

  if (pedido.estado === "PENDIENTE_PAGO") {
    return (
      <section className="mb-5">
        <h3 className={TITULO}>Repartidor</h3>
        <p className="text-xs text-gray-400">Se buscará repartidor al confirmar el pago.</p>
      </section>
    );
  }

  const nombreRepartidor =
    pedido.repartidor?.usuario?.nombre ??
    (pedido.repartidorId ? `Repartidor #${pedido.repartidorId}` : null);
  const intentos = pedido.intentosCodigoFallidos ?? 0;
  const bloqueado = intentos >= MAX_INTENTOS_CODIGO;

  return (
    <section className="mb-5 space-y-3">
      <div>
        <h3 className={TITULO}>Repartidor</h3>

        {error && (
          <p role="alert" className="mb-2 rounded-lg bg-red-50 p-2.5 text-xs text-red-600 dark:bg-red-950/20">
            {error}
          </p>
        )}

        {/* ---- Con repartidor ---- */}
        {nombreRepartidor && (
          <div className="flex items-center justify-between gap-3">
            <p className="text-sm font-semibold text-gray-800 dark:text-gray-200">{nombreRepartidor}</p>
            {gestiona && asignable && (
              <button
                type="button"
                disabled={accion !== null}
                onClick={liberar}
                className="rounded-lg border border-gray-200 px-2.5 py-1 text-[11px] font-bold text-gray-600 hover:bg-gray-50 disabled:opacity-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-gray-800"
              >
                {accion === "liberar" ? "Soltando..." : "Liberar"}
              </button>
            )}
          </div>
        )}
        {nombreRepartidor && gestiona && pedido.estado === "EN_CAMINO" && (
          <p className="mt-1 text-[11px] text-gray-400">
            El pedido ya está en camino: no se puede soltar.
          </p>
        )}

        {/* ---- Sin repartidor: pizza al aire ---- */}
        {!nombreRepartidor && asignable && (
          <div className="rounded-lg border border-error-200 bg-error-50 p-3 dark:border-error-500/20 dark:bg-error-500/10">
            <p className="text-sm font-bold text-error-700 dark:text-error-400">
              Sin repartidor asignado
            </p>
            <p className="mt-0.5 text-xs text-error-600/80 dark:text-error-400/80">
              El pedido no puede despacharse hasta que alguien lo tome.
            </p>
          </div>
        )}

        {/* ---- Top 3 sugeridos ---- */}
        {necesitaAsignacion && (
          <div className="mt-3">
            <div className="mb-2 flex items-center justify-between">
              <span className="text-[11px] font-bold uppercase tracking-wider text-gray-400">
                Sugeridos (carga + distancia)
              </span>
              <button
                type="button"
                disabled={cargandoSugerencia}
                onClick={() => setRecarga((v) => v + 1)}
                className="text-[11px] font-semibold text-brand-600 hover:underline disabled:opacity-50 dark:text-brand-400"
              >
                {cargandoSugerencia ? "Buscando..." : "Actualizar"}
              </button>
            </div>

            {cargandoSugerencia && !sugerencia && (
              <p className="text-xs text-gray-400">Buscando repartidores...</p>
            )}

            {sugerencia && sugerencia.candidatos.length === 0 && (
              <p className="rounded-lg bg-gray-50 p-3 text-xs text-gray-500 dark:bg-gray-800/40 dark:text-gray-400">
                {sugerencia.motivo ?? "No hay candidatos disponibles"}. Se reasignará solo cuando
                se libere cupo.
              </p>
            )}

            {sugerencia && sugerencia.candidatos.length > 0 && (
              <ul className="space-y-2">
                {sugerencia.candidatos.map((c, i) => (
                  <li
                    key={c.repartidorId}
                    className="flex items-center justify-between gap-3 rounded-lg border border-gray-200 p-3 dark:border-gray-700"
                  >
                    <div className="min-w-0">
                      <p className="truncate text-sm font-semibold text-gray-800 dark:text-gray-100">
                        {c.nombre}
                        {i === 0 && (
                          <span className="ml-2 rounded bg-brand-50 px-1.5 py-0.5 text-[10px] font-bold text-brand-600 dark:bg-brand-500/10 dark:text-brand-400">
                            Recomendado
                          </span>
                        )}
                      </p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">
                        {c.pedidosActivos}/{c.capacidadPedidos} pedidos ·{" "}
                        {c.distanciaKm != null ? `${c.distanciaKm} km` : "sin ubicación"}
                        {c.vehiculo ? ` · ${c.vehiculo}` : ""}
                      </p>
                    </div>
                    <button
                      type="button"
                      disabled={accion !== null}
                      onClick={() => asignar(c)}
                      className="shrink-0 rounded-lg bg-brand-500 px-3 py-1.5 text-xs font-bold text-white hover:bg-brand-600 disabled:opacity-50"
                    >
                      {accion === `asignar-${c.repartidorId}` ? "Asignando..." : "Asignar"}
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </div>
        )}
      </div>

      {/* ---- Código de confirmación (solo lo ve administración) ---- */}
      {gestiona && pedido.estado === "EN_CAMINO" && (
        <div
          className={`rounded-lg border p-3 ${
            bloqueado
              ? "border-error-200 bg-error-50 dark:border-error-500/20 dark:bg-error-500/10"
              : "border-gray-200 dark:border-gray-700"
          }`}
        >
          <div className="flex items-center justify-between gap-3">
            <div>
              <p className="text-[11px] font-bold uppercase tracking-wider text-gray-400">
                Código de entrega
              </p>
              <p className="text-2xl font-black tracking-[0.3em] text-gray-900 dark:text-white">
                {pedido.codigoConfirmacion ?? "----"}
              </p>
            </div>
            <div className="text-right">
              <p
                className={`text-xs font-bold ${
                  bloqueado ? "text-error-600 dark:text-error-400" : "text-gray-500 dark:text-gray-400"
                }`}
              >
                {bloqueado ? "Bloqueado" : "Intentos fallidos"}
              </p>
              <p className="text-sm font-semibold text-gray-800 dark:text-gray-200">
                {intentos}/{MAX_INTENTOS_CODIGO}
              </p>
            </div>
          </div>

          <div className="mt-3 flex gap-2">
            <button
              type="button"
              disabled={accion !== null || intentos === 0}
              onClick={() => resetearCodigo(false)}
              className="flex-1 rounded-lg border border-gray-200 py-1.5 text-[11px] font-bold text-gray-700 hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-40 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-gray-800"
            >
              {accion === "reiniciar" ? "Reiniciando..." : "Reiniciar intentos"}
            </button>
            <button
              type="button"
              disabled={accion !== null}
              onClick={() => resetearCodigo(true)}
              className="flex-1 rounded-lg border border-gray-200 py-1.5 text-[11px] font-bold text-gray-700 hover:bg-gray-50 disabled:opacity-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-gray-800"
            >
              {accion === "codigo-nuevo" ? "Generando..." : "Código nuevo"}
            </button>
          </div>
          {bloqueado && (
            <p className="mt-2 text-[11px] text-error-600 dark:text-error-400">
              El repartidor agotó los intentos. Reinicia los intentos o genera un código nuevo.
            </p>
          )}
        </div>
      )}

      {/* ---- Auditoría de la entrega ---- */}
      {pedido.estado === "ENTREGADO" &&
        (pedido.confirmadoEn ? (
          <p className="text-xs font-semibold text-emerald-600 dark:text-emerald-400">
            Entrega confirmada con código ·{" "}
            {new Date(pedido.confirmadoEn).toLocaleTimeString("es-PE", {
              hour: "2-digit",
              minute: "2-digit",
            })}
          </p>
        ) : (
          <p className="text-xs font-semibold text-amber-600 dark:text-amber-400">
            Entregado sin código (cierre manual de administración)
          </p>
        ))}
    </section>
  );
}