// src/modules/pedidos/pedidos.controller.js
const {
  crearPedidoSchema,
  agregarItemsSchema,
  confirmarPagoSchema,
  actualizarEstadoSchema,
  listarPedidosQuerySchema,
  auditarPedidosQuerySchema,
} = require("./pedidos.validation");
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
    const pedido = await pedidosService.crearPedido(req.usuario.id, req.usuario.rol, datos, req.usuario);
    res.status(201).json(pedido);
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

async function agregarItems(req, res, next) {
  try {
    const id = Number(req.params.id);
    const { items } = agregarItemsSchema.parse(req.body);
    const pedido = await pedidosService.agregarItemsAPedido(id, items, req.usuario);
    res.json(pedido);
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

async function confirmarPago(req, res, next) {
  try {
    const id = Number(req.params.id);
    const { metodo } = confirmarPagoSchema.parse(req.body);
    const pedido = await pedidosService.confirmarPago(id, metodo, req.usuario);
    res.json(pedido);
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

async function actualizarEstado(req, res, next) {
  try {
    const id = Number(req.params.id);
    const { estado } = actualizarEstadoSchema.parse(req.body);
    const pedido = await pedidosService.actualizarEstado(id, estado, req.usuario);
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

async function misEntregas(req, res, next) {
  try {
    const entregas = await pedidosService.misEntregas(req.usuario.id);
    res.json(entregas);
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
    const rango = listarPedidosQuerySchema.parse(req.query);
    const pedidos = await pedidosService.listarTodos(rango, req.usuario);
    res.json(pedidos);
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

async function listarHistorial(req, res, next) {
  try {
    const rango = listarPedidosQuerySchema.parse(req.query);
    const pedidos = await pedidosService.listarHistorial(rango, req.usuario);
    res.json(pedidos);
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

async function auditarPedidos(req, res, next) {
  try {
    const filtros = auditarPedidosQuerySchema.parse(req.query);
    const resultado = await pedidosService.auditarPedidos(filtros, req.usuario);
    res.json(resultado);
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

async function obtenerResumenPedidos(req, res, next) {
  try {
    const rango = listarPedidosQuerySchema.parse(req.query);
    const resumen = await pedidosService.obtenerResumenPedidos(rango);
    res.json(resumen);
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

async function obtenerRendimiento(req, res, next) {
  try {
    const rango = listarPedidosQuerySchema.parse(req.query);
    const rendimiento = await pedidosService.obtenerRendimiento(rango, req.usuario);
    res.json(rendimiento);
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

async function obtenerPorId(req, res, next) {
  try {
    const id = Number(req.params.id);
    const pedido = await pedidosService.obtenerPorId(id, req.usuario);
    res.json(pedido);
  } catch (err) {
    next(err);
  }
}

module.exports = {
  crearPedido,
  agregarItems,
  confirmarPago,
  actualizarEstado,
  asignarRepartidor,
  misEntregas,
  misPedidos,
  listarTodos,
  listarHistorial,
  auditarPedidos,
  obtenerResumenPedidos,
  obtenerRendimiento,
  obtenerPorId,
};