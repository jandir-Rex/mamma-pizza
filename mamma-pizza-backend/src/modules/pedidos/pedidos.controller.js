const { crearPedidoSchema, actualizarEstadoSchema } = require("./pedidos.validation");
const pedidosService = require("./pedidos.service");

function manejarZodError(err, res, next) {
  if (err.name === "ZodError") {
    return res.status(400).json({ error: err.issues[0].message });
  }
  next(err);
}

async function crearPedido(req, res, next) {
  try {
    const datos = crearPedidoSchema.parse(req.body);
    const pedido = await pedidosService.crearPedido(req.usuario.id, req.usuario.rol, datos);
    res.status(201).json(pedido);
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

async function confirmarPago(req, res, next) {
  try {
    const id = Number(req.params.id);
    const pedido = await pedidosService.confirmarPago(id);
    res.json(pedido);
  } catch (err) {
    next(err);
  }
}

async function actualizarEstado(req, res, next) {
  try {
    const id = Number(req.params.id);
    const { estado } = actualizarEstadoSchema.parse(req.body);
    const pedido = await pedidosService.actualizarEstado(id, estado);
    res.json(pedido);
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

async function asignarRepartidor(req, res, next) {
  try {
    const id = Number(req.params.id);
    const { repartidorId } = req.body;
    const pedido = await pedidosService.asignarRepartidor(id, Number(repartidorId));
    res.json(pedido);
  } catch (err) {
    next(err);
  }
}

async function misPedidos(req, res, next) {
  try {
    const pedidos = await pedidosService.listarPedidosCliente(req.usuario.id);
    res.json(pedidos);
  } catch (err) {
    next(err);
  }
}

async function listarTodos(req, res, next) {
  try {
    const pedidos = await pedidosService.listarTodos();
    res.json(pedidos);
  } catch (err) {
    next(err);
  }
}

async function obtenerPorId(req, res, next) {
  try {
    const id = Number(req.params.id);
    const pedido = await pedidosService.obtenerPorId(id);
    res.json(pedido);
  } catch (err) {
    next(err);
  }
}

module.exports = {
  crearPedido,
  confirmarPago,
  actualizarEstado,
  asignarRepartidor,
  misPedidos,
  listarTodos,
  obtenerPorId,
};