const { crearMesaSchema, actualizarMesaSchema } = require("./mesas.validation");
const mesasService = require("./mesas.service");

function manejarZodError(err, res, next) {
  if (err.name === "ZodError") {
    return res.status(400).json({ error: err.issues[0].message });
  }
  next(err);
}

async function crearMesa(req, res, next) {
  try {
    const datos = crearMesaSchema.parse(req.body);
    res.status(201).json(await mesasService.crearMesa(datos));
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

async function listarMesas(req, res, next) {
  try {
    res.json(await mesasService.listarMesas());
  } catch (err) {
    next(err);
  }
}

async function estadoMesas(req, res, next) {
  try {
    res.json(await mesasService.estadoMesas());
  } catch (err) {
    next(err);
  }
}

async function obtenerMesa(req, res, next) {
  try {
    res.json(await mesasService.obtenerMesaPorId(Number(req.params.id)));
  } catch (err) {
    next(err);
  }
}

async function actualizarMesa(req, res, next) {
  try {
    const datos = actualizarMesaSchema.parse(req.body);
    res.json(await mesasService.actualizarMesa(Number(req.params.id), datos));
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

async function eliminarMesa(req, res, next) {
  try {
    await mesasService.eliminarMesa(Number(req.params.id));
    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

module.exports = { crearMesa, listarMesas, estadoMesas, obtenerMesa, actualizarMesa, eliminarMesa };