const { z } = require("zod");
const service = require("./forecasting.service");

const generarSchema = z.object({
  mes: z.string().regex(/^\d{4}-(0[1-9]|1[0-2])$/, "El mes debe tener formato AAAA-MM").optional(),
});

async function generar(req, res, next) {
  try {
    const { mes } = generarSchema.parse(req.body ?? {});
    const resultado = await service.generar({ mes, usuarioId: req.usuario.id });
    res.status(201).json(resultado);
  } catch (err) {
    if (err.name === "ZodError") return res.status(400).json({ error: err.issues[0].message });
    next(err);
  }
}

async function resumen(req, res, next) {
  try {
    const ultimo = await service.ultimo();
    res.json(ultimo ?? { sinEjecuciones: true });
  } catch (err) { next(err); }
}

async function historial(req, res, next) {
  try { res.json(await service.historial()); } catch (err) { next(err); }
}

async function obtener(req, res, next) {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id) || id <= 0) return res.status(400).json({ error: "Id inválido" });
    res.json(await service.obtenerPorId(id));
  } catch (err) { next(err); }
}

async function estado(req, res, next) {
  try { res.json(await service.estadoServicio()); } catch (err) { next(err); }
}

async function precision(req, res, next) {
  try { res.json(await service.precision()); } catch (err) { next(err); }
}

module.exports = { generar, resumen, historial, obtener, estado, precision };
