const prisma = require("../../config/prisma");
const python = require("./python.client");
const { hoyLima, sumarDias, inicioDiaLima, diaLima, periodoDeMes, mesSiguiente } = require("./fechas");

// Estados de pedido que cuentan como venta real (los CANCELADO y PENDIENTE_PAGO NO). Confirmar con el negocio.
const VENTA_VALIDA = ["CONFIRMADO", "EN_PREPARACION", "EN_CAMINO", "ENTREGADO"];
const DIAS_HISTORIAL = 610; // ~20 meses

let enEjecucion = false;

function httpError(mensaje, status) {
  const e = new Error(mensaje);
  e.status = status;
  return e;
}

// Ventas diarias agregadas por producto (solo datos de negocio; sin datos de clientes)
async function obtenerVentas(desdeISO, hastaISO) {
  const filas = await prisma.pedidoItem.findMany({
    where: {
      pedido: {
        estado: { in: VENTA_VALIDA },
        createdAt: { gte: inicioDiaLima(desdeISO), lt: inicioDiaLima(sumarDias(hastaISO, 1)) },
      },
    },
    select: {
      cantidad: true,
      pedido: { select: { createdAt: true } },
      productoVariante: { select: { producto: { select: { id: true, nombre: true } } } },
    },
  });

  const acumulado = new Map();
  for (const f of filas) {
    const producto = f.productoVariante.producto;
    const fecha = diaLima(f.pedido.createdAt);
    const clave = `${producto.id}|${fecha}`;
    const actual = acumulado.get(clave);
    if (actual) actual.cantidad += f.cantidad;
    else acumulado.set(clave, { producto_id: producto.id, nombre: producto.nombre, fecha, cantidad: f.cantidad });
  }
  return [...acumulado.values()];
}

// Punto de extension (Fase 1 del plan): aqui se leeran recetas e inventario cuando existan en la base de datos.
async function obtenerRecetasEInventario() {
  return { recetas: [], inventario: [] };
}

function formatear(run) {
  return { id: run.id, creadoEn: run.createdAt, duracionMs: run.duracionMs, ...(run.resultado || {}) };
}

async function generar({ mes, usuarioId }) {
  if (enEjecucion) throw httpError("Ya hay un pronóstico en ejecución. Espera a que termine.", 409);
  enEjecucion = true;
  const t0 = Date.now();
  try {
    const hoy = hoyLima();
    const fechaCorte = sumarDias(hoy, -1); // hoy esta incompleto: se usan datos hasta ayer
    const periodo = periodoDeMes(mes || mesSiguiente(hoy));
    if (periodo.inicio <= fechaCorte) {
      throw httpError("El periodo a pronosticar debe ser un mes futuro (posterior al último día con datos).", 400);
    }

    const ventas = await obtenerVentas(sumarDias(fechaCorte, -DIAS_HISTORIAL), fechaCorte);
    const { recetas, inventario } = await obtenerRecetasEInventario();
    const payload = {
      periodo,
      fecha_corte: fechaCorte,
      ventas,
      recetas,
      inventario,
      config: { ia_habilitada: process.env.FORECAST_AI_ENABLED !== "false" },
    };

    const base = {
      periodoInicio: new Date(`${periodo.inicio}T00:00:00Z`),
      periodoFin: new Date(`${periodo.fin}T00:00:00Z`),
      fechaCorte: new Date(`${fechaCorte}T00:00:00Z`),
      solicitadoPorId: usuarioId ?? null,
    };

    let resultado;
    try {
      resultado = await python.analizar(payload);
    } catch (err) {
      await prisma.forecastRun.create({
        data: { ...base, estado: "error", error: err.message.slice(0, 500), duracionMs: Date.now() - t0 },
      });
      throw err;
    }

    const run = await prisma.forecastRun.create({
      data: { ...base, estado: resultado.estado, resultado, duracionMs: Date.now() - t0 },
    });
    return formatear(run);
  } finally {
    enEjecucion = false;
  }
}

async function ultimo() {
  const run = await prisma.forecastRun.findFirst({
    where: { estado: { in: ["completado", "parcial"] } },
    orderBy: { createdAt: "desc" },
  });
  return run ? formatear(run) : null;
}

async function obtenerPorId(id) {
  const run = await prisma.forecastRun.findUnique({ where: { id } });
  if (!run) throw httpError("Ejecución no encontrada", 404);
  return formatear(run);
}

async function historial() {
  const runs = await prisma.forecastRun.findMany({
    orderBy: { createdAt: "desc" },
    take: 50,
    select: { id: true, periodoInicio: true, periodoFin: true, estado: true, error: true, duracionMs: true, createdAt: true },
  });
  return runs;
}

async function estadoServicio() {
  try {
    const h = await python.health();
    return { disponible: true, ...h };
  } catch (err) {
    return { disponible: false, motivo: err.message };
  }
}

// Compara pronosticos de ejecuciones pasadas con las ventas reales del periodo (MAE y WAPE por ejecucion)
async function precision() {
  const hoy = hoyLima();
  const runs = await prisma.forecastRun.findMany({
    where: { estado: { in: ["completado", "parcial"] }, periodoFin: { lt: new Date(`${hoy}T00:00:00Z`) } },
    orderBy: { periodoFin: "desc" },
    take: 12,
  });

  const salida = [];
  for (const run of runs) {
    const inicio = run.periodoInicio.toISOString().slice(0, 10);
    const fin = run.periodoFin.toISOString().slice(0, 10);
    const reales = new Map();
    for (const v of await obtenerVentas(inicio, fin)) {
      reales.set(v.producto_id, (reales.get(v.producto_id) || 0) + v.cantidad);
    }

    const productos = [];
    let sumaErr = 0, sumaReal = 0, sumaErrIA = 0, sumaRealIA = 0, nIA = 0;
    for (const p of run.resultado?.productos || []) {
      if (p.pronostico_final == null) continue;
      const real = reales.get(p.producto_id) || 0;
      const diferencia = p.pronostico_final - real;
      sumaErr += Math.abs(diferencia);
      sumaReal += real;
      if (p.pronostico_ia != null) {
        sumaErrIA += Math.abs(p.pronostico_ia - real);
        sumaRealIA += real;
        nIA += 1;
      }
      productos.push({ producto_id: p.producto_id, nombre: p.nombre, pronostico: p.pronostico_final, pronostico_ia: p.pronostico_ia ?? null, real, diferencia: Math.round(diferencia * 10) / 10 });
    }
    salida.push({
      runId: run.id,
      periodo: { inicio, fin },
      productosEvaluados: productos.length,
      mae: productos.length ? Math.round((sumaErr / productos.length) * 100) / 100 : null,
      wape: sumaReal > 0 ? Math.round((sumaErr / sumaReal) * 10000) / 10000 : null,
      wapeIA: nIA > 0 && sumaRealIA > 0 ? Math.round((sumaErrIA / sumaRealIA) * 10000) / 10000 : null,
      productos,
    });
  }
  return salida;
}

module.exports = { generar, ultimo, obtenerPorId, historial, estadoServicio, precision };
