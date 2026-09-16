const {
  ubicacionSchema,
  disponibilidadSchema,
  vehiculoSchema,
} = require("./repartidores.validation");
const repartidoresService = require("./repartidores.service");

function manejarZodError(err, res, next) {
  if (err.name === "ZodError") {
    return res.status(400).json({ error: err.issues[0].message });
  }
  next(err);
}

async function actualizarUbicacion(req, res, next) {
  try {
    const { lat, lng } = ubicacionSchema.parse(req.body);
    res.json(await repartidoresService.actualizarUbicacion(req.usuario.id, lat, lng));
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

async function actualizarDisponibilidad(req, res, next) {
  try {
    const { disponible } = disponibilidadSchema.parse(req.body);
    res.json(await repartidoresService.actualizarDisponibilidad(req.usuario.id, disponible));
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

async function actualizarVehiculo(req, res, next) {
  try {
    const { vehiculo } = vehiculoSchema.parse(req.body);
    res.json(await repartidoresService.actualizarVehiculo(req.usuario.id, vehiculo));
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

async function listarTodos(req, res, next) {
  try {
    res.json(await repartidoresService.listarTodos());
  } catch (err) {
    next(err);
  }
}

async function listarDisponibles(req, res, next) {
  try {
    res.json(await repartidoresService.listarDisponibles());
  } catch (err) {
    next(err);
  }
}

async function sugerirParaPedido(req, res, next) {
  try {
    const pedidoId = Number(req.params.pedidoId);
    res.json(await repartidoresService.sugerirParaPedido(pedidoId));
  } catch (err) {
    next(err);
  }
}

module.exports = {
  actualizarUbicacion,
  actualizarDisponibilidad,
  actualizarVehiculo,
  listarTodos,
  listarDisponibles,
  sugerirParaPedido,
};