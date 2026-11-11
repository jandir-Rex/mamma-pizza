// src/components/analiticas/graficos.tsx
// Gráficas propias (SVG/CSS), sin librerías: ligeras, nítidas y con el mismo lenguaje visual del panel.
import { useEffect, useMemo, useRef, useState } from "react";

const MARCA = "#465fff";
const nf = (v: number, dec = 0) => v.toLocaleString("es-PE", { maximumFractionDigits: dec });

function useAncho<T extends HTMLElement>() {
  const ref = useRef<T>(null);
  const [ancho, setAncho] = useState(0);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    setAncho(Math.floor(el.getBoundingClientRect().width));
    const obs = new ResizeObserver((entradas) => setAncho(Math.floor(entradas[0].contentRect.width)));
    obs.observe(el);
    return () => obs.disconnect();
  }, []);
  return [ref, ancho] as const;
}

function pasoLimpio(x: number) {
  const p = 10 ** Math.floor(Math.log10(x || 1));
  const f = x / p;
  return (f <= 1 ? 1 : f <= 2 ? 2 : f <= 5 ? 5 : 10) * p;
}

function escalaY(max: number, marcas = 4) {
  const paso = pasoLimpio(Math.max(max, 1) / marcas);
  const tope = Math.ceil(Math.max(max, 1) / paso) * paso;
  return { tope, paso };
}

const colores = (oscuro: boolean) => ({
  rejilla: oscuro ? "#263147" : "#eaecf0",
  texto: oscuro ? "#98a2b3" : "#667085",
  fuerte: oscuro ? "#ffffff" : "#101828",
  fondo: oscuro ? "#101828" : "#ffffff",
});

/* ===================== Línea con proyección y banda ===================== */
export type PuntoHistoria = { etiqueta: string; valor: number; parcial?: boolean };
export type Proyeccion = { etiqueta: string; valor: number; bajo: number | null; alto: number | null };

export function LineaProyeccion({ historia, proyeccion, oscuro, alto = 300 }: { historia: PuntoHistoria[]; proyeccion: Proyeccion; oscuro: boolean; alto?: number }) {
  const [ref, ancho] = useAncho<HTMLDivElement>();
  const [hover, setHover] = useState<number | null>(null);
  const c = colores(oscuro);

  const geom = useMemo(() => {
    if (ancho === 0) return null;
    const M = { l: 44, r: 30, t: 46, b: 30 };
    const w = ancho - M.l - M.r;
    const h = alto - M.t - M.b;
    const n = historia.length + 1;
    const x = (i: number) => M.l + 12 + (n === 1 ? (w - 24) / 2 : (i * (w - 24)) / (n - 1));
    const maxVal = Math.max(...historia.map((p) => p.valor), proyeccion.alto ?? 0, proyeccion.valor, 1);
    const { tope, paso } = escalaY(maxVal * 1.08);
    const y = (v: number) => M.t + h - (v / tope) * h;
    const base = y(0);
    const marcas: number[] = [];
    for (let v = 0; v <= tope + 1e-9; v += paso) marcas.push(v);

    const completos = historia.map((p, i) => ({ ...p, i })).filter((p) => !p.parcial);
    const linea = completos.map((p, k) => `${k === 0 ? "M" : "L"}${x(p.i).toFixed(1)} ${y(p.valor).toFixed(1)}`).join(" ");
    const area = completos.length > 1 ? `${linea} L${x(completos[completos.length - 1].i).toFixed(1)} ${base} L${x(completos[0].i).toFixed(1)} ${base} Z` : "";
    const ultimo = completos[completos.length - 1];
    const xp = x(n - 1);
    const conector = ultimo ? `M${x(ultimo.i).toFixed(1)} ${y(ultimo.valor).toFixed(1)} L${xp.toFixed(1)} ${y(proyeccion.valor).toFixed(1)}` : "";
    return { M, w, h, n, x, y, base, marcas, linea, area, conector, xp, completos };
  }, [ancho, alto, historia, proyeccion]);

  if (!geom) return <div ref={ref} style={{ height: alto }} />;
  const { M, n, x, y, base, marcas, linea, area, conector, xp, completos } = geom;
  const saltoEtiqueta = (ancho - M.l - M.r) / n < 40 ? 2 : 1;
  const anclaEtiqueta = xp + 40 > ancho ? "end" : "middle";
  const xEtiqueta = anclaEtiqueta === "end" ? ancho - 4 : xp;
  const hayBanda = proyeccion.bajo != null && proyeccion.alto != null;
  const todos = [...historia.map((p) => ({ ...p, proy: false })), { etiqueta: proyeccion.etiqueta, valor: proyeccion.valor, parcial: false, proy: true }];

  const mover = (e: React.MouseEvent<SVGRectElement>) => {
    const caja = e.currentTarget.getBoundingClientRect();
    const px = e.clientX - caja.left + M.l;
    let mejor = 0;
    for (let i = 0; i < n; i++) if (Math.abs(x(i) - px) < Math.abs(x(mejor) - px)) mejor = i;
    setHover(mejor);
  };
  const hp = hover != null ? todos[hover] : null;

  return (
    <div ref={ref} className="relative" onMouseLeave={() => setHover(null)}>
      <svg width={ancho} height={alto} role="img" aria-label={`Ventas mensuales y proyección de ${proyeccion.etiqueta}: ${nf(proyeccion.valor)} unidades`}>
        <defs>
          <linearGradient id="relleno-linea" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={MARCA} stopOpacity={oscuro ? 0.3 : 0.2} />
            <stop offset="100%" stopColor={MARCA} stopOpacity={0} />
          </linearGradient>
        </defs>

        {marcas.map((v) => (
          <g key={v}>
            <line x1={M.l} x2={ancho - M.r} y1={y(v)} y2={y(v)} stroke={c.rejilla} strokeWidth={1} strokeDasharray={v === 0 ? undefined : "3 4"} />
            <text x={M.l - 8} y={y(v) + 4} textAnchor="end" fontSize={11} fill={c.texto}>
              {nf(v)}
            </text>
          </g>
        ))}

        {area && <path d={area} fill="url(#relleno-linea)" />}
        {linea && <path d={linea} fill="none" stroke={MARCA} strokeWidth={2.25} strokeLinejoin="round" strokeLinecap="round" />}
        {conector && <path d={conector} fill="none" stroke={MARCA} strokeWidth={2} strokeDasharray="5 5" strokeLinecap="round" opacity={0.85} />}

        {hayBanda && (
          <g>
            <rect x={xp - 13} y={y(proyeccion.alto as number)} width={26} height={Math.max(2, y(proyeccion.bajo as number) - y(proyeccion.alto as number))} rx={6} fill={MARCA} opacity={0.14} />
            <line x1={xp - 13} x2={xp + 13} y1={y(proyeccion.alto as number)} y2={y(proyeccion.alto as number)} stroke={MARCA} strokeWidth={1.5} opacity={0.55} />
            <line x1={xp - 13} x2={xp + 13} y1={y(proyeccion.bajo as number)} y2={y(proyeccion.bajo as number)} stroke={MARCA} strokeWidth={1.5} opacity={0.55} />
          </g>
        )}

        {completos.map((p) => (
          <circle key={p.i} cx={x(p.i)} cy={y(p.valor)} r={3.5} fill={c.fondo} stroke={MARCA} strokeWidth={2} />
        ))}
        <circle cx={xp} cy={y(proyeccion.valor)} r={11} fill={MARCA} opacity={0.16} />
        <circle cx={xp} cy={y(proyeccion.valor)} r={5.5} fill={MARCA} stroke={c.fondo} strokeWidth={2} />

        <text x={xEtiqueta} y={Math.max(16, y(proyeccion.alto ?? proyeccion.valor) - 24)} textAnchor={anclaEtiqueta} fontSize={20} fontWeight={800} fill={c.fuerte}>
          {nf(proyeccion.valor)}
        </text>
        <text x={xEtiqueta} y={Math.max(30, y(proyeccion.alto ?? proyeccion.valor) - 10)} textAnchor={anclaEtiqueta} fontSize={10.5} fontWeight={600} fill={MARCA} letterSpacing={0.4}>
          PROYECCIÓN
        </text>

        {todos.map((p, i) =>
          i % saltoEtiqueta === 0 || i === n - 1 ? (
            <text key={i} x={x(i)} y={base + 20} textAnchor="middle" fontSize={11} fill={p.proy ? MARCA : c.texto} fontWeight={p.proy ? 700 : 400} opacity={p.parcial ? 0.55 : 1} fontStyle={p.parcial ? "italic" : "normal"}>
              {p.etiqueta}
              {p.parcial ? "*" : ""}
            </text>
          ) : null,
        )}

        {hover != null && <line x1={x(hover)} x2={x(hover)} y1={M.t - 6} y2={base} stroke={c.texto} strokeWidth={1} strokeDasharray="2 3" opacity={0.6} />}
        <rect x={M.l} y={0} width={ancho - M.l - M.r + 20} height={alto} fill="transparent" onMouseMove={mover} />
      </svg>

      {hp && hover != null && (
        <div
          className="pointer-events-none absolute z-10 rounded-lg border border-gray-200 bg-white px-3 py-2 text-xs shadow-md dark:border-gray-700 dark:bg-gray-800"
          style={{ left: Math.min(Math.max(x(hover) - 70, 4), ancho - 150), top: 4 }}
        >
          <p className="font-semibold text-gray-900 dark:text-white">
            {hp.etiqueta}
            {hp.parcial ? " · mes en curso" : ""}
          </p>
          <p className="text-gray-600 dark:text-gray-300">
            {nf(hp.valor)} u.{hp.proy && hayBanda ? ` · rango ${nf(proyeccion.bajo as number)}–${nf(proyeccion.alto as number)}` : ""}
          </p>
        </div>
      )}
    </div>
  );
}

/* ============================ Calendario de calor ============================ */
const DIAS_CORTO = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];
const DIAS_LARGO = ["lunes", "martes", "miércoles", "jueves", "viernes", "sábados", "domingos"];
const MES_CORTO = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"];

export function MapaCalor({ fechas, valores, oscuro }: { fechas: string[]; valores: number[]; oscuro: boolean }) {
  const datos = useMemo(() => {
    if (fechas.length === 0) return null;
    const dia = (iso: string) => new Date(`${iso}T12:00:00Z`);
    const dow = (d: Date) => (d.getUTCDay() + 6) % 7;
    const primero = dia(fechas[0]);
    const inicio = new Date(primero.getTime() - dow(primero) * 86400000);
    const mapa = new Map(fechas.map((f, i) => [f, valores[i]]));
    const ultimo = dia(fechas[fechas.length - 1]);
    const semanas = Math.floor((ultimo.getTime() - inicio.getTime()) / 86400000 / 7) + 1;
    const max = Math.max(...valores, 1);

    const celdas: { s: number; d: number; valor: number | null; iso: string }[] = [];
    for (let s = 0; s < semanas; s++)
      for (let d = 0; d < 7; d++) {
        const f = new Date(inicio.getTime() + (s * 7 + d) * 86400000);
        const iso = f.toISOString().slice(0, 10);
        celdas.push({ s, d, valor: mapa.has(iso) ? (mapa.get(iso) as number) : null, iso });
      }
    const meses: { s: number; etiqueta: string }[] = [];
    let previo = -1;
    for (let s = 0; s < semanas; s++) {
      const jueves = new Date(inicio.getTime() + (s * 7 + 3) * 86400000);
      const m = jueves.getUTCMonth();
      if (m !== previo) meses.push({ s, etiqueta: MES_CORTO[m] });
      previo = m;
    }
    if (meses.length > 1 && meses[1].s - meses[0].s < 3) meses.shift();
    const suma = Array(7).fill(0);
    const cuenta = Array(7).fill(0);
    celdas.forEach((c) => {
      if (c.valor != null) {
        suma[c.d] += c.valor;
        cuenta[c.d] += 1;
      }
    });
    const prom = suma.map((s, i) => (cuenta[i] ? s / cuenta[i] : 0));
    const mejor = prom.indexOf(Math.max(...prom));
    return { semanas, celdas, meses, max, prom, mejor };
  }, [fechas, valores]);

  if (!datos) return <p className="text-xs text-gray-400">Sin ventas suficientes para el calendario.</p>;
  const { semanas, celdas, meses, max, prom, mejor } = datos;
  const neutro = oscuro ? "#1d2939" : "#f2f4f7";
  const tono = (v: number) => `rgba(70, 95, 255, ${(0.16 + 0.84 * Math.pow(v / max, 0.75)).toFixed(3)})`;
  const escala = [0.12, 0.35, 0.6, 0.8, 1].map((t) => `rgba(70, 95, 255, ${(0.16 + 0.84 * Math.pow(t, 0.75)).toFixed(3)})`);

  return (
    <div>
      <div className="grid gap-1" style={{ gridTemplateColumns: `28px repeat(${semanas}, minmax(0, 34px))`, justifyContent: "start" }} role="img" aria-label="Calendario de ventas diarias por semana">
        <div />
        {Array.from({ length: semanas }, (_, s) => (
          <div key={s} className="h-4 overflow-visible whitespace-nowrap text-[10px] font-medium text-gray-400">
            {meses.find((m) => m.s === s)?.etiqueta ?? ""}
          </div>
        ))}
        {DIAS_CORTO.map((nombre, d) => (
          <div key={nombre} className="contents">
            <div className="flex items-center text-[10px] font-medium text-gray-400">{d % 2 === 0 ? nombre : ""}</div>
            {Array.from({ length: semanas }, (_, s) => {
              const cel = celdas[s * 7 + d];
              if (cel.valor == null) return <div key={s} className="aspect-square" />;
              const f = new Date(`${cel.iso}T12:00:00Z`);
              return (
                <div
                  key={s}
                  title={`${DIAS_CORTO[d]} ${f.getUTCDate()} ${MES_CORTO[f.getUTCMonth()]} · ${nf(cel.valor, 1)} u.`}
                  className="aspect-square rounded-[5px] transition-transform hover:scale-110"
                  style={{ background: cel.valor > 0 ? tono(cel.valor) : neutro }}
                />
              );
            })}
          </div>
        ))}
      </div>
      <div className="mt-4 flex items-center justify-between gap-3">
        <p className="text-xs text-gray-500">
          El día más fuerte son los <b className="text-gray-800 dark:text-gray-200">{DIAS_LARGO[mejor]}</b> ({nf(prom[mejor], 1)} u. de promedio).
        </p>
        <div className="flex shrink-0 items-center gap-1.5 text-[10px] text-gray-400">
          Menos
          {escala.map((col, i) => (
            <span key={i} className="size-3 rounded-[3px]" style={{ background: col }} />
          ))}
          Más
        </div>
      </div>
      <div className="mt-5 space-y-1.5 border-t border-gray-100 pt-4 dark:border-gray-800">
        <p className="mb-2 text-[11px] font-bold uppercase tracking-wider text-gray-400">Promedio por día de la semana</p>
        {DIAS_CORTO.map((nombre, d) => (
          <div key={nombre} className="grid grid-cols-[30px_1fr_44px] items-center gap-2">
            <span className="text-[11px] text-gray-500">{nombre}</span>
            <div className="h-1.5 overflow-hidden rounded-full bg-gray-100 dark:bg-gray-800">
              <div className={`h-full rounded-full ${d === mejor ? "bg-brand-500" : "bg-brand-300"}`} style={{ width: `${(prom[d] / Math.max(...prom, 1)) * 100}%` }} />
            </div>
            <span className="text-right text-[11px] tabular-nums text-gray-500">{nf(prom[d], 1)}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

/* ============================ Variación por pizza (barras divergentes) ============================ */
export function Variaciones({ filas }: { filas: { nombre: string; previsto: number; delta: number | null }[] }) {
  const tope = Math.max(10, ...filas.map((f) => Math.abs(f.delta ?? 0)));
  return (
    <div>
      <div className="space-y-2.5">
        {filas.map((f) => {
          const ancho = f.delta == null ? 0 : (Math.abs(f.delta) / tope) * 46;
          const sube = (f.delta ?? 0) >= 0;
          return (
            <div key={f.nombre} className="grid grid-cols-[minmax(80px,26%)_1fr_64px] items-center gap-3">
              <span className="truncate text-xs font-semibold text-gray-700 dark:text-gray-300">{f.nombre}</span>
              <div className="relative h-6">
                <div className="absolute inset-y-0 left-1/2 w-px bg-gray-200 dark:bg-gray-700" />
                {f.delta != null && (
                  <>
                    <div
                      className={`absolute top-1/2 h-3.5 -translate-y-1/2 ${sube ? "rounded-r-md bg-emerald-400" : "rounded-l-md bg-red-400"}`}
                      style={sube ? { left: "50%", width: `${Math.max(ancho, 0.8)}%` } : { right: "50%", width: `${Math.max(ancho, 0.8)}%` }}
                    />
                    <span
                      className={`absolute top-1/2 -translate-y-1/2 text-[11px] font-bold tabular-nums ${sube ? "text-emerald-600" : "text-red-600"}`}
                      style={sube ? { left: `calc(50% + ${Math.max(ancho, 0.8)}% + 6px)` } : { right: `calc(50% + ${Math.max(ancho, 0.8)}% + 6px)` }}
                    >
                      {sube ? "+" : "−"}
                      {nf(Math.abs(f.delta), 1)} %
                    </span>
                  </>
                )}
              </div>
              <span className="text-right text-xs tabular-nums text-gray-500">{nf(f.previsto)} u.</span>
            </div>
          );
        })}
      </div>
      <p className="mt-4 text-[11px] text-gray-400">Cambio previsto frente al periodo anterior. La línea central es 0 %.</p>
    </div>
  );
}

/* ============================ Barras de demanda por pizza ============================ */
export function BarrasDemanda({ filas }: { filas: { nombre: string; valor: number }[] }) {
  const max = Math.max(...filas.map((f) => f.valor), 1);
  return (
    <div className="space-y-3">
      {filas.map((f) => (
        <div key={f.nombre} className="grid grid-cols-[minmax(80px,28%)_1fr_44px] items-center gap-3">
          <span className="truncate text-xs font-semibold text-gray-700 dark:text-gray-300">{f.nombre}</span>
          <div className="h-2 overflow-hidden rounded-full bg-gray-100 dark:bg-gray-800">
            <div className="h-full rounded-full bg-brand-500" style={{ width: `${(f.valor / max) * 100}%` }} />
          </div>
          <span className="text-right text-xs font-bold tabular-nums text-gray-800 dark:text-gray-200">{nf(f.valor)}</span>
        </div>
      ))}
    </div>
  );
}

/* ============================ Minigráfico de tendencia ============================ */
export function Sparkline({ valores, proyeccion, oscuro }: { valores: number[]; proyeccion: number | null; oscuro: boolean }) {
  const W = 88;
  const H = 28;
  const pts = [...valores];
  const todos = proyeccion != null ? [...pts, proyeccion] : pts;
  if (todos.length === 0) return <span className="text-gray-300">—</span>;
  const max = Math.max(...todos, 1);
  const x = (i: number) => 3 + (todos.length === 1 ? (W - 6) / 2 : (i * (W - 6)) / (todos.length - 1));
  const y = (v: number) => H - 4 - (v / max) * (H - 8);
  const linea = pts.map((v, i) => `${i === 0 ? "M" : "L"}${x(i).toFixed(1)} ${y(v).toFixed(1)}`).join(" ");
  const ultimo = pts.length - 1;
  const c = colores(oscuro);
  return (
    <svg width={W} height={H} aria-hidden>
      {pts.length > 1 && <path d={linea} fill="none" stroke={MARCA} strokeWidth={1.75} strokeLinecap="round" strokeLinejoin="round" />}
      {proyeccion != null && pts.length > 0 && <path d={`M${x(ultimo).toFixed(1)} ${y(pts[ultimo]).toFixed(1)} L${x(todos.length - 1).toFixed(1)} ${y(proyeccion).toFixed(1)}`} stroke={MARCA} strokeWidth={1.75} strokeDasharray="3 3" fill="none" opacity={0.8} />}
      {pts.length > 0 && <circle cx={x(ultimo)} cy={y(pts[ultimo])} r={2} fill={c.fondo} stroke={MARCA} strokeWidth={1.5} />}
      {proyeccion != null && <circle cx={x(todos.length - 1)} cy={y(proyeccion)} r={3} fill={MARCA} />}
    </svg>
  );
}

/* ============================ Barras apiladas de actividad ============================ */
export type PicoActividad = { periodo: string; actividad: number; registrados: number; continuados: number; finalizados: number };

export function BarrasActividad({ picos, etiqueta }: { picos: PicoActividad[]; etiqueta: (periodo: string) => string }) {
  const max = Math.max(1, ...picos.map((p) => p.actividad));
  const ALTO = 112;
  return (
    <div className="flex min-h-40 items-end gap-2 overflow-x-auto border-b border-gray-100 pb-2 dark:border-gray-800">
      {picos.map((p) => {
        const total = Math.max(6, (p.actividad / max) * ALTO);
        const suma = Math.max(1, p.registrados + p.continuados + p.finalizados);
        const seg = (n: number) => `${(n / suma) * 100}%`;
        return (
          <div key={p.periodo} className="flex min-w-10 flex-1 flex-col items-center justify-end gap-2">
            <span className="text-[10px] font-semibold text-gray-500">{p.actividad}</span>
            <div
              title={`${p.periodo}: ${p.registrados} registros, ${p.continuados} continuaciones, ${p.finalizados} finalizaciones`}
              className="flex w-full max-w-12 flex-col-reverse overflow-hidden rounded-t-md"
              style={{ height: `${total}px` }}
            >
              <div className="bg-brand-500" style={{ height: seg(p.registrados) }} />
              <div className="bg-brand-300" style={{ height: seg(p.continuados) }} />
              <div className="bg-gray-700 dark:bg-gray-300" style={{ height: seg(p.finalizados) }} />
            </div>
            <span className="whitespace-nowrap text-[10px] text-gray-500">{etiqueta(p.periodo)}</span>
          </div>
        );
      })}
    </div>
  );
}
