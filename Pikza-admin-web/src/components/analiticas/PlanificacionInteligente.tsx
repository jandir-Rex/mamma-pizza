// src/components/analiticas/PlanificacionInteligente.tsx
import { Fragment, useCallback, useEffect, useState } from "react";
import { apiRequest } from "@/services/api";

type Confianza = "alta" | "media" | "baja" | "insuficiente";

type Producto = {
  producto_id: number;
  nombre: string;
  ventas_periodo_anterior: number;
  pronostico_estadistico: number | null;
  limite_inferior: number | null;
  limite_superior: number | null;
  variacion_pct: number | null;
  modelo: string | null;
  metricas: { wape: number | null; mae: number | null; ventanas: number };
  confianza: Confianza;
  advertencias: string[];
  pronostico_ia: number | null;
  pronostico_final: number | null;
};

type Ingrediente = {
  ingrediente_id: number;
  nombre: string;
  unidad: string;
  necesidad_ajustada: number;
  inventario_disponible: number;
  compras_pendientes: number;
  stock_seguridad: number;
  compra_sugerida: number;
  alerta_faltante: boolean;
  detalle: string[];
};

type Recomendacion = {
  tipo: string;
  severidad: "info" | "atencion" | "critica";
  mensaje: string;
  fundamento: string;
  origen: "reglas" | "ia";
};

type Motor = { estado: string; detalle: string; modelo?: string | null };

type Pronostico = {
  id: number;
  creadoEn: string;
  estado: "completado" | "parcial";
  periodo: { inicio: string; fin: string };
  fecha_corte: string;
  motores: Record<string, Motor>;
  datos: { dias_historial?: number };
  productos: Producto[];
  ingredientes: Ingrediente[];
  evaluacion: { modo: string; motivo: string };
  analisis_ia: { resumen: string; tendencias: string[]; alertas: string[]; recomendaciones: string[] } | null;
  recomendaciones: Recomendacion[];
  advertencias: string[];
};

type Respuesta = Pronostico | { sinEjecuciones: true };

type PrecisionRun = {
  runId: number;
  periodo: { inicio: string; fin: string };
  productosEvaluados: number;
  mae: number | null;
  wape: number | null;
  wapeIA: number | null;
};

type EstadoServicio = { disponible: boolean; motivo?: string; ia_configurada?: boolean };

const MESES = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"];

function opcionesMes(): { valor: string; etiqueta: string }[] {
  const hoy = new Date();
  return [1, 2, 3].map((n) => {
    const d = new Date(hoy.getFullYear(), hoy.getMonth() + n, 1);
    return { valor: `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`, etiqueta: `${MESES[d.getMonth()]} ${d.getFullYear()}` };
  });
}

const num = (v: number | null | undefined, dec = 1) =>
  v == null ? "—" : v.toLocaleString("es-PE", { maximumFractionDigits: dec });
const pct = (v: number | null | undefined) => (v == null ? "—" : `${(v * 100).toLocaleString("es-PE", { maximumFractionDigits: 1 })} %`);

const COLOR_CONFIANZA: Record<Confianza, string> = {
  alta: "bg-emerald-50 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400",
  media: "bg-amber-50 text-amber-700 dark:bg-amber-500/10 dark:text-amber-400",
  baja: "bg-orange-50 text-orange-700 dark:bg-orange-500/10 dark:text-orange-400",
  insuficiente: "bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400",
};
const COLOR_SEVERIDAD: Record<Recomendacion["severidad"], string> = {
  info: "border-gray-200 dark:border-gray-800",
  atencion: "border-amber-300 bg-amber-50/50 dark:border-amber-500/30 dark:bg-amber-500/5",
  critica: "border-red-300 bg-red-50/60 dark:border-red-500/30 dark:bg-red-500/5",
};
const COLOR_MOTOR: Record<string, string> = {
  completado: "bg-emerald-50 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400",
  deshabilitado: "bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400",
  omitido: "bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400",
  no_disponible: "bg-amber-50 text-amber-700 dark:bg-amber-500/10 dark:text-amber-400",
  error: "bg-red-50 text-red-700 dark:bg-red-500/10 dark:text-red-400",
};
const NOMBRE_MOTOR: Record<string, string> = { estadistico: "Motor estadístico", ia_cloud: "IA en la nube", evaluacion: "Evaluación" };

const tarjeta = "rounded-xl border border-gray-200 bg-white shadow-xs dark:border-gray-800 dark:bg-gray-900";
const th = "px-4 py-3 text-left text-[11px] font-bold uppercase tracking-wider text-gray-500";
const td = "px-4 py-3 text-sm text-gray-700 dark:text-gray-300 tabular-nums";

export default function PlanificacionInteligente() {
  const meses = opcionesMes();
  const [mes, setMes] = useState(meses[0].valor);
  const [datos, setDatos] = useState<Pronostico | null>(null);
  const [servicio, setServicio] = useState<EstadoServicio | null>(null);
  const [cargando, setCargando] = useState(true);
  const [generando, setGenerando] = useState(false);
  const [error, setError] = useState("");
  const [abierto, setAbierto] = useState<number | null>(null);
  const [precision, setPrecision] = useState<PrecisionRun[] | null>(null);
  const [cargandoPrecision, setCargandoPrecision] = useState(false);

  const cargar = useCallback(async () => {
    setError("");
    try {
      const [resumen, estado] = await Promise.all([
        apiRequest<Respuesta>("/forecasting/overview"),
        apiRequest<EstadoServicio>("/forecasting/status"),
      ]);
      setDatos("sinEjecuciones" in resumen ? null : resumen);
      setServicio(estado);
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudo cargar la planificación");
    } finally {
      setCargando(false);
    }
  }, []);

  useEffect(() => {
    void cargar();
  }, [cargar]);

  async function generar() {
    setGenerando(true);
    setError("");
    try {
      const nuevo = await apiRequest<Pronostico>("/forecasting/generate", { method: "POST", body: JSON.stringify({ mes }) });
      setDatos(nuevo);
      setPrecision(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudo generar el pronóstico");
    } finally {
      setGenerando(false);
    }
  }

  async function verPrecision() {
    setCargandoPrecision(true);
    try {
      setPrecision(await apiRequest<PrecisionRun[]>("/forecasting/accuracy"));
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudo cargar la precisión");
    } finally {
      setCargandoPrecision(false);
    }
  }

  const totalUnidades = datos?.productos.reduce((s, p) => s + (p.pronostico_final ?? 0), 0) ?? 0;
  const conPronostico = datos?.productos.filter((p) => p.pronostico_final != null) ?? [];
  const masDemanda = [...conPronostico].sort((a, b) => (b.pronostico_final ?? 0) - (a.pronostico_final ?? 0)).slice(0, 3);

  return (
    <section className="space-y-4" aria-labelledby="planificacion-titulo">
      <div className={`${tarjeta} p-5`}>
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 id="planificacion-titulo" className="text-lg font-bold text-gray-900 dark:text-white">
              Predicción y abastecimiento
            </h2>
            <p className="mt-1 text-xs text-gray-500">
              Estimaciones a partir de las ventas históricas. Son proyecciones con incertidumbre, no certezas.
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <select
              value={mes}
              onChange={(e) => setMes(e.target.value)}
              disabled={generando}
              aria-label="Mes a pronosticar"
              className="h-10 rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-700 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-200"
            >
              {meses.map((m) => (
                <option key={m.valor} value={m.valor}>
                  {m.etiqueta}
                </option>
              ))}
            </select>
            <button
              type="button"
              onClick={generar}
              disabled={generando || servicio?.disponible === false}
              className="h-10 rounded-lg bg-brand-500 px-4 text-sm font-bold text-white hover:bg-brand-600 disabled:cursor-not-allowed disabled:opacity-50"
            >
              {generando ? "Generando…" : "Generar pronóstico"}
            </button>
          </div>
        </div>
        {generando && <p className="mt-3 text-xs text-gray-500">Analizando ventas históricas. Puede tardar hasta un par de minutos.</p>}
        {servicio?.disponible === false && (
          <p role="alert" className="mt-3 rounded-lg bg-amber-50 p-3 text-xs text-amber-700 dark:bg-amber-500/10 dark:text-amber-400">
            El servicio de predicción no está disponible ahora. Los pedidos y las ventas no se ven afectados.
            {servicio.motivo ? ` (${servicio.motivo})` : ""}
          </p>
        )}
        {error && (
          <p role="alert" className="mt-3 rounded-lg bg-red-50 p-3 text-xs text-red-600 dark:bg-red-500/10 dark:text-red-400">
            {error}
          </p>
        )}
      </div>

      {cargando ? (
        <div className={`${tarjeta} p-6 text-sm text-gray-500`}>Cargando…</div>
      ) : !datos ? (
        <div className={`${tarjeta} p-6 text-sm text-gray-500`}>
          Todavía no se ha generado ningún pronóstico. Elige un mes y pulsa «Generar pronóstico».
        </div>
      ) : (
        <>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <div className={`${tarjeta} p-5`}>
              <p className="text-xs font-bold uppercase tracking-wider text-gray-500">Periodo</p>
              <p className="mt-1 text-lg font-black text-gray-900 dark:text-white">
                {datos.periodo.inicio} → {datos.periodo.fin}
              </p>
              <p className="mt-1 text-xs text-gray-500">
                Datos hasta {datos.fecha_corte} · generado {new Date(datos.creadoEn).toLocaleString("es-PE")}
              </p>
            </div>
            <div className={`${tarjeta} p-5`}>
              <p className="text-xs font-bold uppercase tracking-wider text-gray-500">Unidades estimadas</p>
              <p className="mt-1 text-2xl font-black text-brand-500 tabular-nums">{num(totalUnidades, 0)}</p>
              <p className="mt-1 text-xs text-gray-500">
                {conPronostico.length} de {datos.productos.length} productos con pronóstico
              </p>
            </div>
            <div className={`${tarjeta} p-5 lg:col-span-2`}>
              <p className="text-xs font-bold uppercase tracking-wider text-gray-500">Mayor demanda prevista</p>
              <p className="mt-1 text-sm font-semibold text-gray-800 dark:text-white/90">
                {masDemanda.length ? masDemanda.map((p) => `${p.nombre} (${num(p.pronostico_final, 0)})`).join(" · ") : "Sin datos suficientes"}
              </p>
              <div className="mt-2 flex flex-wrap gap-2">
                {Object.entries(datos.motores).map(([clave, m]) => (
                  <span key={clave} title={m.detalle} className={`rounded-full px-2.5 py-1 text-[11px] font-semibold ${COLOR_MOTOR[m.estado] ?? COLOR_MOTOR.omitido}`}>
                    {NOMBRE_MOTOR[clave] ?? clave}: {m.estado.replace("_", " ")}
                  </span>
                ))}
              </div>
            </div>
          </div>

          {datos.advertencias.length > 0 && (
            <div className="rounded-xl border border-amber-300 bg-amber-50/60 p-4 dark:border-amber-500/30 dark:bg-amber-500/5">
              <p className="text-xs font-bold uppercase tracking-wider text-amber-700 dark:text-amber-400">Advertencias y limitaciones</p>
              <ul className="mt-2 list-disc space-y-1 pl-5 text-xs text-amber-800 dark:text-amber-300">
                {datos.advertencias.map((a, i) => (
                  <li key={i}>{a}</li>
                ))}
              </ul>
            </div>
          )}

          <div className={`${tarjeta} overflow-hidden`}>
            <div className="border-b border-gray-100 px-5 py-4 dark:border-gray-800">
              <h3 className="text-sm font-bold text-gray-900 dark:text-white">Pronóstico por pizza</h3>
              <p className="text-xs text-gray-500">
                Modelo elegido por backtesting. El rango es aproximado (80 %) y solo aparece con suficientes pruebas históricas.
              </p>
            </div>
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-100 dark:divide-gray-800">
                <thead>
                  <tr>
                    <th className={th}>Producto</th>
                    <th className={th}>Periodo anterior</th>
                    <th className={th}>Previsto</th>
                    <th className={th}>Rango</th>
                    <th className={th}>Variación</th>
                    <th className={th}>Modelo</th>
                    <th className={th}>Error (WAPE)</th>
                    <th className={th}>Confianza</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                  {datos.productos.map((p) => (
                    <tr key={p.producto_id} title={p.advertencias.join(" ")}>
                      <td className={`${td} font-semibold`}>{p.nombre}</td>
                      <td className={td}>{num(p.ventas_periodo_anterior, 0)}</td>
                      <td className={`${td} font-bold`}>{num(p.pronostico_final, 0)}</td>
                      <td className={td}>{p.limite_inferior != null ? `${num(p.limite_inferior, 0)} – ${num(p.limite_superior, 0)}` : "—"}</td>
                      <td className={`${td} ${p.variacion_pct != null && p.variacion_pct < 0 ? "text-red-600" : "text-emerald-600"}`}>
                        {p.variacion_pct != null ? `${p.variacion_pct > 0 ? "+" : ""}${num(p.variacion_pct)} %` : "—"}
                      </td>
                      <td className={td}>{p.modelo?.replace(/_/g, " ") ?? "—"}</td>
                      <td className={td}>{pct(p.metricas.wape)}</td>
                      <td className={td}>
                        <span className={`rounded-full px-2.5 py-1 text-[11px] font-semibold ${COLOR_CONFIANZA[p.confianza]}`}>{p.confianza}</span>
                      </td>
                    </tr>
                  ))}
                  {datos.productos.length === 0 && (
                    <tr>
                      <td colSpan={8} className="px-4 py-6 text-center text-sm text-gray-500">
                        No hay ventas históricas válidas para pronosticar.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>

          <div className={`${tarjeta} overflow-hidden`}>
            <div className="border-b border-gray-100 px-5 py-4 dark:border-gray-800">
              <h3 className="text-sm font-bold text-gray-900 dark:text-white">Plan de abastecimiento</h3>
              <p className="text-xs text-gray-500">
                Cálculo determinista: recetas × demanda prevista − inventario − compras pendientes. La IA no interviene.
              </p>
            </div>
            {datos.ingredientes.length === 0 ? (
              <p className="px-5 py-6 text-sm text-gray-500">
                Aún no hay recetas e inventario registrados, por eso no se puede calcular qué comprar. Cuando existan, esta tabla mostrará la compra sugerida por ingrediente.
              </p>
            ) : (
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-100 dark:divide-gray-800">
                  <thead>
                    <tr>
                      <th className={th}>Ingrediente</th>
                      <th className={th}>Necesidad</th>
                      <th className={th}>Inventario</th>
                      <th className={th}>Pendiente</th>
                      <th className={th}>Seguridad</th>
                      <th className={th}>Compra sugerida</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                    {datos.ingredientes.map((i) => (
                      <Fragment key={i.ingrediente_id}>
                        <tr
                          onClick={() => setAbierto(abierto === i.ingrediente_id ? null : i.ingrediente_id)}
                          className="cursor-pointer hover:bg-gray-50 dark:hover:bg-white/3"
                        >
                          <td className={`${td} font-semibold`}>
                            {i.alerta_faltante && (
                              <span title="El inventario no cubre la necesidad" className="mr-1 text-red-500">
                                ●
                              </span>
                            )}
                            {i.nombre}
                          </td>
                          <td className={td}>{num(i.necesidad_ajustada, 2)} {i.unidad}</td>
                          <td className={td}>{num(i.inventario_disponible, 2)} {i.unidad}</td>
                          <td className={td}>{num(i.compras_pendientes, 2)} {i.unidad}</td>
                          <td className={td}>{num(i.stock_seguridad, 2)} {i.unidad}</td>
                          <td className={`${td} font-bold`}>{num(i.compra_sugerida, 2)} {i.unidad}</td>
                        </tr>
                        {abierto === i.ingrediente_id && (
                          <tr>
                            <td colSpan={6} className="bg-gray-50 px-5 py-3 text-xs text-gray-600 dark:bg-white/3 dark:text-gray-400">
                              {i.detalle.map((l, k) => (
                                <p key={k}>{l}</p>
                              ))}
                            </td>
                          </tr>
                        )}
                      </Fragment>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          <div className={`${tarjeta} p-5`}>
            <h3 className="text-sm font-bold text-gray-900 dark:text-white">Recomendaciones</h3>
            <div className="mt-3 space-y-2">
              {datos.recomendaciones.length === 0 && <p className="text-sm text-gray-500">Sin recomendaciones para este periodo.</p>}
              {datos.recomendaciones.map((r, i) => (
                <div key={i} className={`rounded-lg border p-3 ${COLOR_SEVERIDAD[r.severidad]}`}>
                  <p className="text-sm font-semibold text-gray-800 dark:text-white/90">
                    {r.origen === "ia" && (
                      <span className="mr-2 rounded bg-brand-50 px-1.5 py-0.5 text-[10px] font-bold text-brand-600">Análisis automatizado (IA)</span>
                    )}
                    {r.mensaje}
                  </p>
                  <p className="mt-1 text-xs text-gray-500">{r.fundamento}</p>
                </div>
              ))}
            </div>
            {datos.analisis_ia && (
              <div className="mt-4 rounded-lg bg-gray-50 p-4 dark:bg-white/3">
                <p className="text-[11px] font-bold uppercase tracking-wider text-gray-500">
                  Resumen de la IA (análisis automatizado, verificar antes de actuar)
                </p>
                <p className="mt-1 text-sm text-gray-700 dark:text-gray-300">{datos.analisis_ia.resumen}</p>
                {datos.analisis_ia.tendencias.length > 0 && (
                  <ul className="mt-2 list-disc space-y-1 pl-5 text-xs text-gray-600 dark:text-gray-400">
                    {datos.analisis_ia.tendencias.map((t, i) => (
                      <li key={i}>{t}</li>
                    ))}
                  </ul>
                )}
              </div>
            )}
          </div>

          <div className={`${tarjeta} p-5`}>
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-sm font-bold text-gray-900 dark:text-white">Precisión histórica</h3>
                <p className="text-xs text-gray-500">Compara pronósticos de meses ya terminados con las ventas reales.</p>
              </div>
              <button
                type="button"
                onClick={verPrecision}
                disabled={cargandoPrecision}
                className="h-9 rounded-lg border border-gray-300 px-3 text-xs font-semibold text-gray-700 hover:bg-gray-50 disabled:opacity-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-gray-800"
              >
                {cargandoPrecision ? "Calculando…" : "Ver precisión"}
              </button>
            </div>
            {precision && (
              <div className="mt-3 overflow-x-auto">
                {precision.length === 0 ? (
                  <p className="text-sm text-gray-500">Aún no hay pronósticos de meses terminados para comparar.</p>
                ) : (
                  <table className="min-w-full divide-y divide-gray-100 dark:divide-gray-800">
                    <thead>
                      <tr>
                        <th className={th}>Periodo</th>
                        <th className={th}>Productos</th>
                        <th className={th}>MAE (u.)</th>
                        <th className={th}>WAPE estadístico</th>
                        <th className={th}>WAPE IA</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                      {precision.map((r) => (
                        <tr key={r.runId}>
                          <td className={td}>
                            {r.periodo.inicio} → {r.periodo.fin}
                          </td>
                          <td className={td}>{r.productosEvaluados}</td>
                          <td className={td}>{num(r.mae, 1)}</td>
                          <td className={td}>{pct(r.wape)}</td>
                          <td className={td}>{pct(r.wapeIA)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </div>
            )}
          </div>
        </>
      )}
    </section>
  );
}
