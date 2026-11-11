// src/components/analiticas/PlanificacionInteligente.tsx
import { Fragment, useCallback, useEffect, useMemo, useState } from "react";
import { useTheme } from "@/context/ThemeContext";
import { apiRequest } from "@/services/api";
import { BarrasDemanda, LineaProyeccion, MapaCalor, Sparkline, Variaciones } from "./graficos";
import type { PuntoHistoria } from "./graficos";

/* ----------------------------- Tipos ----------------------------- */
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

type Motor = { estado: string; detalle: string };

type SerieHistorica = {
  meses: string[];
  total: number[];
  mensual_por_producto?: Record<string, number[]>;
  ultimo_mes_parcial: boolean;
  primer_mes_parcial?: boolean;
  semanal: { dias: string[]; promedio: number[]; dias_considerados: number };
  diaria: { fechas: string[]; total: number[] };
};

type Pronostico = {
  id: number;
  creadoEn: string;
  estado: "completado" | "parcial";
  periodo: { inicio: string; fin: string };
  fecha_corte: string;
  motores: Record<string, Motor>;
  datos: { dias_historial?: number; variacion_comparable?: boolean; dias_periodo?: number };
  productos: Producto[];
  ingredientes: Ingrediente[];
  analisis_ia: { resumen: string; tendencias: string[]; alertas: string[]; recomendaciones: string[] } | null;
  serie_historica?: SerieHistorica;
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

type EstadoServicio = { disponible: boolean; motivo?: string };

/* --------------------------- Utilidades --------------------------- */
const MESES = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"];
const MES_CORTO = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"];

function opcionesMes(): { valor: string; etiqueta: string }[] {
  const hoy = new Date();
  return [1, 2, 3].map((n) => {
    const d = new Date(hoy.getFullYear(), hoy.getMonth() + n, 1);
    return { valor: `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`, etiqueta: `${MESES[d.getMonth()]} ${d.getFullYear()}` };
  });
}

const etiquetaMes = (ym: string) => {
  const [y, m] = ym.split("-");
  return `${MES_CORTO[Number(m) - 1]} ${y.slice(2)}`;
};
const nombreMes = (ymd: string) => {
  const [y, m] = ymd.split("-");
  return `${MESES[Number(m) - 1]} ${y}`;
};

const nf = (v: number | null | undefined, dec = 0) => (v == null ? "—" : v.toLocaleString("es-PE", { maximumFractionDigits: dec }));
const pct = (v: number | null | undefined) => (v == null ? "—" : `${(v * 100).toLocaleString("es-PE", { maximumFractionDigits: 1 })} %`);

const PUNTO_CONFIANZA: Record<Confianza, string> = { alta: "bg-emerald-500", media: "bg-amber-500", baja: "bg-orange-500", insuficiente: "bg-gray-300 dark:bg-gray-600" };
const NOMBRE_CONFIANZA: Record<Confianza, string> = { alta: "Alta", media: "Media", baja: "Baja", insuficiente: "Insuficiente" };
const SEVERIDAD = {
  critica: { borde: "border-l-red-500", etiqueta: "Crítica", texto: "text-red-600" },
  atencion: { borde: "border-l-amber-400", etiqueta: "Atención", texto: "text-amber-600" },
  info: { borde: "border-l-brand-500", etiqueta: "Info", texto: "text-brand-500" },
} as const;

const NOMBRE_MODELO: Record<string, string> = {
  ultimo_periodo: "Último periodo",
  promedio_movil: "Promedio móvil",
  perfil_semanal: "Perfil semanal",
  ets_holt_winters: "Suavizado exponencial",
};

const tarjeta = "rounded-xl border border-gray-200 bg-white shadow-xs dark:border-gray-800 dark:bg-gray-900";
const etiqueta = "text-xs font-bold uppercase tracking-wider text-gray-400";
const th = "px-5 py-3 text-left text-[11px] font-bold uppercase tracking-wider text-gray-400";
const td = "px-5 py-3.5 text-sm text-gray-700 dark:text-gray-300 tabular-nums";

function Bloque({ titulo, subtitulo, derecha, children, className = "" }: { titulo: string; subtitulo?: string; derecha?: React.ReactNode; children: React.ReactNode; className?: string }) {
  return (
    <section className={`${tarjeta} overflow-hidden ${className}`}>
      <div className="flex items-start justify-between gap-3 border-b border-gray-100 p-5 dark:border-gray-800">
        <div>
          <h3 className="text-base font-bold text-gray-900 dark:text-white">{titulo}</h3>
          {subtitulo && <p className="text-xs text-gray-500">{subtitulo}</p>}
        </div>
        {derecha}
      </div>
      <div className="p-5">{children}</div>
    </section>
  );
}

/* ------------------------------- Componente ------------------------------- */
export default function PlanificacionInteligente() {
  const { theme } = useTheme();
  const oscuro = theme === "dark";
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
      const [resumen, estado] = await Promise.all([apiRequest<Respuesta>("/forecasting/overview"), apiRequest<EstadoServicio>("/forecasting/status")]);
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

  /* --------- Derivados --------- */
  const r = useMemo(() => {
    if (!datos) return null;
    const conPron = datos.productos.filter((p) => p.pronostico_final != null);
    const total = conPron.reduce((s, p) => s + (p.pronostico_final ?? 0), 0);
    const anterior = conPron.reduce((s, p) => s + p.ventas_periodo_anterior, 0);
    const comparable = datos.datos.variacion_comparable === true;
    const variacion = comparable && anterior > 0 ? ((total - anterior) / anterior) * 100 : null;
    const lider = [...conPron].sort((a, b) => (b.pronostico_final ?? 0) - (a.pronostico_final ?? 0))[0] ?? null;
    const conteo: Record<Confianza, number> = { alta: 0, media: 0, baja: 0, insuficiente: 0 };
    datos.productos.forEach((p) => {
      conteo[p.confianza] += 1;
    });
    // Banda de incertidumbre del total: solo si todos los productos pronosticados tienen rango
    const todosConRango = conPron.length > 0 && conPron.every((p) => p.limite_inferior != null && p.limite_superior != null);
    const bajo = todosConRango ? conPron.reduce((s, p) => s + (p.limite_inferior as number), 0) : null;
    const alto = todosConRango ? conPron.reduce((s, p) => s + (p.limite_superior as number), 0) : null;
    const criticas = datos.recomendaciones.filter((x) => x.severidad === "critica").length;
    const atencion = datos.recomendaciones.filter((x) => x.severidad === "atencion").length;
    const top = [...conPron].sort((a, b) => (b.pronostico_final ?? 0) - (a.pronostico_final ?? 0)).slice(0, 8);
    return { conPron, total, anterior, comparable, variacion, lider, conteo, bajo, alto, criticas, atencion, top };
  }, [datos]);

  const sh = datos?.serie_historica;
  const historia: PuntoHistoria[] = useMemo(() => {
    if (!sh) return [];
    return sh.meses.map((m, i) => ({
      etiqueta: etiquetaMes(m),
      valor: sh.total[i],
      parcial: (i === sh.meses.length - 1 && sh.ultimo_mes_parcial) || (i === 0 && sh.primer_mes_parcial === true),
    }));
  }, [sh]);

  const generarBtn = (
    <button
      type="button"
      onClick={generar}
      disabled={generando || servicio?.disponible === false}
      className="h-10 rounded-xl bg-brand-500 px-4 text-sm font-semibold text-white shadow-xs transition hover:bg-brand-600 disabled:cursor-not-allowed disabled:opacity-50"
    >
      {generando ? "Generando…" : "Generar pronóstico"}
    </button>
  );

  /* -------------------------------- Render -------------------------------- */
  return (
    <section className="space-y-6" aria-labelledby="planificacion-titulo">
      {/* Cabecera: mismo patrón que la de la página */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <p className="text-sm text-gray-500 dark:text-gray-400">Planificación de demanda</p>
          <h2 id="planificacion-titulo" className="text-2xl font-bold text-gray-900 dark:text-white">
            Predicción y abastecimiento
          </h2>
          <p className="mt-1.5 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-gray-500">
            <span className="inline-flex items-center gap-1.5">
              <span className={`size-1.5 rounded-full ${servicio?.disponible ? "bg-emerald-500" : "bg-red-500"}`} />
              Servicio {servicio ? (servicio.disponible ? "activo" : "no disponible") : "…"}
            </span>
            {datos && (
              <span className="inline-flex items-center gap-1.5">
                <span className={`size-1.5 rounded-full ${datos.motores.ia_cloud?.estado === "completado" ? "bg-emerald-500" : "bg-gray-300 dark:bg-gray-600"}`} />
                IA {datos.motores.ia_cloud?.estado === "completado" ? "activa" : "no disponible"}
              </span>
            )}
            {datos && <span>Datos hasta {datos.fecha_corte}</span>}
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-3">
          <div className="flex rounded-xl border border-gray-200 bg-white p-1 dark:border-gray-800 dark:bg-gray-800">
            {meses.map((m) => (
              <button
                key={m.valor}
                type="button"
                disabled={generando}
                onClick={() => setMes(m.valor)}
                className={`rounded-lg px-3.5 py-1.5 text-xs font-bold capitalize transition ${mes === m.valor ? "bg-brand-500 text-white shadow-xs" : "text-gray-600 hover:text-gray-900 dark:text-gray-300"}`}
              >
                {m.etiqueta.split(" ")[0]}
              </button>
            ))}
          </div>
          {generarBtn}
        </div>
      </div>

      {generando && <p className="text-xs text-gray-500">Analizando ventas históricas y evaluando modelos. Puede tardar un par de minutos.</p>}
      {servicio?.disponible === false && (
        <div role="alert" className="rounded-xl bg-amber-50 p-4 text-sm text-amber-700 dark:bg-amber-500/10 dark:text-amber-300">
          El servicio de predicción no está disponible ahora. Los pedidos y las ventas no se ven afectados.
        </div>
      )}
      {error && (
        <div role="alert" className="rounded-xl bg-red-50 p-4 text-sm text-red-600">
          {error}
        </div>
      )}

      {cargando ? (
        <div className={`${tarjeta} p-6 text-sm text-gray-400`}>Cargando…</div>
      ) : !datos || !r ? (
        <div className={`${tarjeta} p-8 text-center`}>
          <p className="text-sm font-semibold text-gray-800 dark:text-white/90">Aún no hay pronósticos</p>
          <p className="mx-auto mt-1 max-w-md text-xs text-gray-500">Elige un mes y pulsa «Generar pronóstico» para ver la demanda estimada de cada pizza.</p>
        </div>
      ) : (
        <>
          {/* Resumen: mismo formato que «Mi rendimiento» */}
          <section className={`${tarjeta} overflow-hidden`}>
            <div className="grid grid-cols-1 divide-y divide-gray-100 sm:grid-cols-2 sm:divide-y-0 lg:grid-cols-4 lg:divide-x dark:divide-gray-800">
              <div className="p-5">
                <p className={etiqueta}>Unidades estimadas</p>
                <p className="mt-1 text-2xl font-black text-brand-500 tabular-nums">{nf(r.total)}</p>
                <p className="mt-1 text-xs text-gray-500">
                  {r.variacion != null ? (
                    <span className={r.variacion >= 0 ? "font-semibold text-emerald-600" : "font-semibold text-red-600"}>
                      {r.variacion >= 0 ? "+" : "−"}
                      {nf(Math.abs(r.variacion), 1)} % vs periodo anterior
                    </span>
                  ) : (
                    <>Para {nombreMes(datos.periodo.inicio)}</>
                  )}
                </p>
              </div>
              <div className="p-5">
                <p className={etiqueta}>Pizza líder</p>
                <p className="mt-1 truncate text-lg font-bold text-gray-900 dark:text-white">{r.lider ? r.lider.nombre : "—"}</p>
                <p className="mt-0.5 text-xs font-semibold text-brand-500">{r.lider ? `${nf(r.lider.pronostico_final)} u. · ${nf(((r.lider.pronostico_final ?? 0) / Math.max(r.total, 1)) * 100)} % del total` : "Sin datos suficientes"}</p>
              </div>
              <div className="p-5">
                <p className={etiqueta}>Pronósticos fiables</p>
                <p className="mt-1 text-2xl font-black text-emerald-600 tabular-nums dark:text-emerald-400">
                  {r.conteo.alta + r.conteo.media}
                  <span className="text-base font-bold text-gray-400"> / {datos.productos.length}</span>
                </p>
                <div className="mt-2 flex h-1.5 overflow-hidden rounded-full bg-gray-100 dark:bg-gray-800" aria-label="Distribución de confianza">
                  {(["alta", "media", "baja", "insuficiente"] as Confianza[]).map((k) => (r.conteo[k] ? <div key={k} className={PUNTO_CONFIANZA[k]} style={{ width: `${(r.conteo[k] / datos.productos.length) * 100}%` }} title={`${NOMBRE_CONFIANZA[k]}: ${r.conteo[k]}`} /> : null))}
                </div>
                <p className="mt-1.5 text-xs text-gray-500">Confianza alta o media · {nf(datos.datos.dias_historial)} días de historial</p>
              </div>
              <div className="p-5">
                <p className={etiqueta}>Alertas</p>
                <p className={`mt-1 text-2xl font-black tabular-nums ${r.criticas > 0 ? "text-red-600" : "text-gray-900 dark:text-white"}`}>{r.criticas + r.atencion}</p>
                <p className="mt-1 text-xs text-gray-500">
                  {r.criticas} crítica{r.criticas === 1 ? "" : "s"} · {r.atencion} de atención
                </p>
              </div>
            </div>
          </section>

          {datos.advertencias.length > 0 && (
            <details className={`${tarjeta} group px-5 py-3`}>
              <summary className="cursor-pointer list-none text-xs font-semibold text-gray-600 dark:text-gray-300">
                {datos.advertencias.length} limitaci{datos.advertencias.length === 1 ? "ón" : "ones"} de este pronóstico <span className="text-brand-500 group-open:hidden">· ver</span>
              </summary>
              <ul className="mt-3 list-disc space-y-1 pl-5 text-xs text-gray-500">
                {datos.advertencias.map((a, i) => (
                  <li key={i}>{a}</li>
                ))}
              </ul>
            </details>
          )}

          {/* Tendencia + calendario */}
          {!sh ? (
            <div className={`${tarjeta} p-5 text-sm text-gray-500`}>Este pronóstico se generó antes de las gráficas históricas. Pulsa «Generar pronóstico» para verlas.</div>
          ) : (
            <div className={`grid grid-cols-1 gap-4 xl:grid-cols-5 ${historia.some((h) => !h.parcial) ? "" : "xl:items-start"}`}>
              <Bloque className="xl:col-span-3" titulo="Demanda mensual" subtitulo="Unidades vendidas por mes y proyección del mes elegido">
                {historia.filter((h) => !h.parcial).length === 0 ? (
                  <div className="flex flex-col items-center justify-center py-10 text-center">
                    <p className={etiqueta}>Proyección de {nombreMes(datos.periodo.inicio)}</p>
                    <p className="mt-1 text-4xl font-black tabular-nums text-brand-500">{nf(r.total)}</p>
                    <p className="mt-3 max-w-sm text-xs text-gray-500">
                      Todavía no hay un mes completo de ventas, así que la línea de tendencia mensual aparecerá cuando termine el primer mes completo.
                    </p>
                  </div>
                ) : (
                  <LineaProyeccion historia={historia} proyeccion={{ etiqueta: etiquetaMes(datos.periodo.inicio.slice(0, 7)), valor: r.total, bajo: r.bajo, alto: r.alto }} oscuro={oscuro} alto={350} />
                )}
                <p className="mt-3 text-xs text-gray-400">
                  {(sh.ultimo_mes_parcial || sh.primer_mes_parcial) && "Los meses marcados con * están incompletos, por eso no entran en la línea. "}
                  {r.bajo != null ? "La barra de la proyección indica el rango probable (80 %)." : "El rango probable aparece cuando hay suficiente historial."}
                </p>
              </Bloque>
              <Bloque className="xl:col-span-2" titulo="Calendario de ventas" subtitulo={`Unidades por día, últimas ${Math.max(1, Math.round(sh.diaria.fechas.length / 7))} semanas`}>
                <MapaCalor fechas={sh.diaria.fechas} valores={sh.diaria.total} oscuro={oscuro} />
              </Bloque>
            </div>
          )}

          {/* Demanda por pizza + recomendaciones */}
          <div className="grid grid-cols-1 gap-4 xl:grid-cols-2">
            <Bloque titulo={r.comparable ? "Variación por pizza" : "Demanda prevista por pizza"} subtitulo={r.comparable ? `Variación prevista por pizza, ${datos.datos.dias_periodo ?? 30} días` : `Unidades previstas para ${nombreMes(datos.periodo.inicio)}`}>
              {r.top.length === 0 ? (
                <p className="py-6 text-center text-xs text-gray-400">Ninguna pizza tiene historial suficiente para pronosticar.</p>
              ) : r.comparable ? (
                <Variaciones filas={r.top.map((p) => ({ nombre: p.nombre, previsto: p.pronostico_final ?? 0, delta: p.variacion_pct }))} />
              ) : (
                <>
                  <BarrasDemanda filas={r.top.map((p) => ({ nombre: p.nombre, valor: p.pronostico_final ?? 0 }))} />
                  <p className="mt-4 text-xs text-gray-400">La comparación con el periodo anterior aparecerá cuando haya al menos el doble de historial que el mes pronosticado.</p>
                </>
              )}
            </Bloque>

            <Bloque titulo="Recomendaciones" subtitulo="Reglas de negocio sobre el pronóstico">
              {datos.recomendaciones.length === 0 ? (
                <p className="py-6 text-center text-xs text-gray-400">Sin recomendaciones para este periodo.</p>
              ) : (
                <ul className="-my-1 divide-y divide-gray-100 dark:divide-gray-800">
                  {datos.recomendaciones.map((x, i) => (
                    <li key={i} className={`border-l-2 py-3 pl-4 ${SEVERIDAD[x.severidad].borde}`}>
                      <p className="text-sm font-semibold text-gray-900 dark:text-white/90">
                        <span className={`mr-2 text-[10px] font-bold uppercase tracking-wider ${SEVERIDAD[x.severidad].texto}`}>{x.origen === "ia" ? "IA" : SEVERIDAD[x.severidad].etiqueta}</span>
                        {x.mensaje}
                      </p>
                      <p className="mt-0.5 text-xs text-gray-500">{x.fundamento}</p>
                    </li>
                  ))}
                </ul>
              )}
              {datos.analisis_ia && (
                <div className="mt-4 border-t border-gray-100 pt-4 dark:border-gray-800">
                  <p className={etiqueta}>Resumen de la IA · verificar antes de actuar</p>
                  <p className="mt-1 text-sm text-gray-700 dark:text-gray-300">{datos.analisis_ia.resumen}</p>
                </div>
              )}
            </Bloque>
          </div>

          {/* Detalle por pizza */}
          <section className={`${tarjeta} overflow-hidden`}>
            <div className="border-b border-gray-100 p-5 dark:border-gray-800">
              <h3 className="text-base font-bold text-gray-900 dark:text-white">Detalle por pizza</h3>
              <p className="text-xs text-gray-500">Modelo elegido por backtesting. El rango (80 %) solo aparece con suficientes pruebas históricas.</p>
            </div>
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-100 dark:divide-gray-800">
                <thead>
                  <tr>
                    <th className={th}>Producto</th>
                    <th className={th}>Tendencia</th>
                    <th className={th}>Anterior</th>
                    <th className={th}>Previsto</th>
                    <th className={th}>Rango</th>
                    <th className={th}>Variación</th>
                    <th className={th}>Modelo</th>
                    <th className={th}>Error</th>
                    <th className={th}>Confianza</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                  {datos.productos.map((p) => {
                    const serie = sh?.mensual_por_producto?.[String(p.producto_id)];
                    const completos = serie ? (sh?.ultimo_mes_parcial ? serie.slice(0, -1) : serie) : [];
                    return (
                      <tr key={p.producto_id} title={p.advertencias.join(" ")} className="hover:bg-gray-50/70 dark:hover:bg-white/3">
                        <td className={`${td} font-semibold text-gray-900 dark:text-white`}>{p.nombre}</td>
                        <td className={td}>{serie ? <Sparkline valores={completos} proyeccion={p.pronostico_final} oscuro={oscuro} /> : "—"}</td>
                        <td className={td}>{nf(p.ventas_periodo_anterior)}</td>
                        <td className={`${td} font-bold text-gray-900 dark:text-white`}>{nf(p.pronostico_final)}</td>
                        <td className={td}>{p.limite_inferior != null ? `${nf(p.limite_inferior)} – ${nf(p.limite_superior)}` : "—"}</td>
                        <td className={td}>
                          {r.comparable && p.variacion_pct != null ? (
                            <span className={`font-semibold ${p.variacion_pct < 0 ? "text-red-600" : "text-emerald-600"}`}>
                              {p.variacion_pct > 0 ? "+" : ""}
                              {nf(p.variacion_pct, 1)} %
                            </span>
                          ) : (
                            <span title="Se necesita al menos el doble de historial que el periodo pronosticado">—</span>
                          )}
                        </td>
                        <td className={td}>{p.modelo ? (NOMBRE_MODELO[p.modelo] ?? p.modelo) : "—"}</td>
                        <td className={td}>{pct(p.metricas.wape)}</td>
                        <td className={td}>
                          <span className="inline-flex items-center gap-2 text-xs font-semibold">
                            <span className={`size-2 rounded-full ${PUNTO_CONFIANZA[p.confianza]}`} />
                            {NOMBRE_CONFIANZA[p.confianza]}
                          </span>
                        </td>
                      </tr>
                    );
                  })}
                  {datos.productos.length === 0 && (
                    <tr>
                      <td colSpan={9} className="px-5 py-8 text-center text-xs text-gray-400">
                        No hay ventas históricas válidas para pronosticar.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </section>

          {/* Abastecimiento */}
          <section className={`${tarjeta} overflow-hidden`}>
            <div className="border-b border-gray-100 p-5 dark:border-gray-800">
              <h3 className="text-base font-bold text-gray-900 dark:text-white">Plan de abastecimiento</h3>
              <p className="text-xs text-gray-500">Recetas × demanda prevista − inventario − compras pendientes. Cálculo directo, sin IA.</p>
            </div>
            {datos.ingredientes.length === 0 ? (
              <p className="p-5 text-sm text-gray-500">
                Todavía no se puede calcular qué comprar: faltan las recetas (ingredientes por pizza) y el inventario. Cuando estén registrados, aquí aparecerá la compra sugerida por ingrediente y cuánto cubre tu inventario.
              </p>
            ) : (
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-100 dark:divide-gray-800">
                  <thead>
                    <tr>
                      <th className={th}>Ingrediente</th>
                      <th className={th}>Necesidad</th>
                      <th className={th}>Inventario</th>
                      <th className={th}>Cobertura</th>
                      <th className={th}>Compra sugerida</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                    {datos.ingredientes.map((i) => {
                      const cobertura = Math.round(((i.inventario_disponible + i.compras_pendientes) / Math.max(i.necesidad_ajustada, 0.0001)) * 100);
                      return (
                        <Fragment key={i.ingrediente_id}>
                          <tr onClick={() => setAbierto(abierto === i.ingrediente_id ? null : i.ingrediente_id)} className="cursor-pointer hover:bg-gray-50/70 dark:hover:bg-white/3">
                            <td className={`${td} font-semibold text-gray-900 dark:text-white`}>{i.nombre}</td>
                            <td className={td}>
                              {nf(i.necesidad_ajustada, 2)} {i.unidad}
                            </td>
                            <td className={td}>
                              {nf(i.inventario_disponible, 2)} {i.unidad}
                            </td>
                            <td className={td}>
                              <div className="flex items-center gap-2">
                                <div className="h-1.5 w-28 overflow-hidden rounded-full bg-gray-100 dark:bg-gray-800">
                                  <div className={`h-full rounded-full ${cobertura < 100 ? "bg-red-500" : "bg-emerald-500"}`} style={{ width: `${Math.min(100, cobertura)}%` }} />
                                </div>
                                <span className={`text-xs font-semibold ${cobertura < 100 ? "text-red-600" : "text-emerald-600"}`}>{cobertura} %</span>
                              </div>
                            </td>
                            <td className={`${td} font-bold text-gray-900 dark:text-white`}>
                              {nf(i.compra_sugerida, 2)} {i.unidad}
                            </td>
                          </tr>
                          {abierto === i.ingrediente_id && (
                            <tr>
                              <td colSpan={5} className="bg-gray-50 px-5 py-3 text-xs text-gray-500 dark:bg-white/3">
                                {i.detalle.map((l, k) => (
                                  <p key={k}>{l}</p>
                                ))}
                              </td>
                            </tr>
                          )}
                        </Fragment>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </section>

          {/* Precisión */}
          <section className={`${tarjeta} overflow-hidden`}>
            <div className="flex items-center justify-between gap-3 border-b border-gray-100 p-5 dark:border-gray-800">
              <div>
                <h3 className="text-base font-bold text-gray-900 dark:text-white">Precisión histórica</h3>
                <p className="text-xs text-gray-500">Pronósticos de meses ya terminados frente a las ventas reales</p>
              </div>
              <button type="button" onClick={verPrecision} disabled={cargandoPrecision} className="h-9 shrink-0 rounded-lg border border-gray-200 px-3 text-xs font-bold text-gray-600 transition hover:text-gray-900 disabled:opacity-50 dark:border-gray-700 dark:text-gray-300">
                {cargandoPrecision ? "Calculando…" : "Ver precisión"}
              </button>
            </div>
            {precision === null ? (
              <p className="p-5 text-xs text-gray-400">Pulsa «Ver precisión» para medir qué tan bien acertó el sistema en meses anteriores.</p>
            ) : precision.length === 0 ? (
              <p className="p-5 text-xs text-gray-400">Aún no hay pronósticos de meses terminados para comparar.</p>
            ) : (
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-100 dark:divide-gray-800">
                  <thead>
                    <tr>
                      <th className={th}>Periodo</th>
                      <th className={th}>Productos</th>
                      <th className={th}>Error medio (u.)</th>
                      <th className={th}>Error estadístico</th>
                      <th className={th}>Error IA</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                    {precision.map((x) => (
                      <tr key={x.runId}>
                        <td className={td}>
                          {x.periodo.inicio} → {x.periodo.fin}
                        </td>
                        <td className={td}>{x.productosEvaluados}</td>
                        <td className={td}>{nf(x.mae, 1)}</td>
                        <td className={td}>{pct(x.wape)}</td>
                        <td className={td}>{pct(x.wapeIA)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </section>
        </>
      )}
    </section>
  );
}
