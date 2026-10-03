const {
  crearAgregadoSchema,
  actualizarAgregadoSchema,
  actualizarPrecioSchema,
} = require("./agregados.validation");
const agregadosService = require("./agregados.service");

function manejarZodError(err, res, next) {
  if (err.name === "ZodError") {
    return res.status(400).json({ error: err.issues[0].message });
  }
  next(err);
}

async function crearAgregado(req, res, next) {
  try {
    const datos = crearAgregadoSchema.parse(req.body);
    res.status(201).json(await agregadosService.crearAgregado(datos));
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

async function listarAgregados(req, res, next) {
  try {
    res.json(await agregadosService.listarAgregados());
  } catch (err) {
    next(err);
  }
}

async function actualizarAgregado(req, res, next) {
  try {
    const id = Number(req.params.id);
    const datos = actualizarAgregadoSchema.parse(req.body);
    res.json(await agregadosService.actualizarAgregado(id, datos));
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

async function actualizarPrecio(req, res, next) {
  try {
    const id = Number(req.params.id);
    const { tamano, precio } = actualizarPrecioSchema.parse(req.body);
    res.json(await agregadosService.actualizarPrecio(id, tamano, precio));
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

module.exports = { crearAgregado, listarAgregados, actualizarAgregado, actualizarPrecio };