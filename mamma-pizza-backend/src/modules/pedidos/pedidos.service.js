const prisma = require("../../config/prisma");

function generarCodigo() {
  return `PZ-${Date.now().toString(36).toUpperCase()}`;
}

async function crearPedido(clienteId, datos) {
  const { canal, direccionId, mesaId, metodoPago, items } = datos;

  return prisma.$transaction(async (tx) => {
    let subtotal = 0;
    const itemsParaCrear = [];

    for (const item of items) {
      // Bloqueo de fila: nadie más puede leer/tocar esta variante hasta que termine la transacción
      const filas = await tx.$queryRaw`
        SELECT id, precio, disponible FROM producto_variantes WHERE id = ${item.productoVarianteId} FOR UPDATE
      `;
      const variante = filas[0];

      if (!variante) {
        const error = new Error(`La variante ${item.productoVarianteId} no existe`);
        error.status = 404;
        throw error;
      }

      if (!variante.disponible) {
        const error = new Error("Uno de los productos elegidos ya no está disponible");
        error.status = 409;
        throw error;
      }

      const precioUnitario = Number(variante.precio);
      subtotal += precioUnitario * item.cantidad;

      itemsParaCrear.push({
        productoVarianteId: item.productoVarianteId,
        cantidad: item.cantidad,
        precioUnitario,
        notas: item.notas,
      });
    }

    const pedido = await tx.pedido.create({
      data: {
        codigo: generarCodigo(),
        clienteId,
        canal,
        estado: "PENDIENTE_PAGO",
        direccionId: canal === "DELIVERY" ? direccionId : null,
        mesaId: canal === "SALON" ? mesaId : null,
        subtotal,
        total: subtotal,
        items: { create: itemsParaCrear },
        pago: {
          create: { metodo: metodoPago, monto: subtotal, estado: "pendiente" },
        },
      },
      include: { items: true, pago: true },
    });

    return pedido;
  });
}

async function confirmarPago(pedidoId) {
  return prisma.$transaction(async (tx) => {
    const pedido = await tx.pedido.findUnique({ where: { id: pedidoId } });

    if (!pedido) {
      const error = new Error("Pedido no encontrado");
      error.status = 404;
      throw error;
    }
    if (pedido.estado !== "PENDIENTE_PAGO") {
      const error = new Error("Este pedido ya fue procesado");
      error.status = 409;
      throw error;
    }

    await tx.pago.update({ where: { pedidoId }, data: { estado: "pagado" } });

    return tx.pedido.update({
      where: { id: pedidoId },
      data: { estado: "CONFIRMADO" },
      include: { items: true, pago: true },
    });
  });
}

async function actualizarEstado(pedidoId, nuevoEstado) {
  const pedido = await prisma.pedido.findUnique({ where: { id: pedidoId } });
  if (!pedido) {
    const error = new Error("Pedido no encontrado");
    error.status = 404;
    throw error;
  }

  return prisma.pedido.update({ where: { id: pedidoId }, data: { estado: nuevoEstado } });
}

async function listarPedidosCliente(clienteId) {
  return prisma.pedido.findMany({
    where: { clienteId },
    include: { items: true, pago: true },
    orderBy: { createdAt: "desc" },
  });
}

async function listarTodos() {
  return prisma.pedido.findMany({
    include: { items: true, pago: true, cliente: { select: { nombre: true, telefono: true } } },
    orderBy: { createdAt: "desc" },
  });
}

async function obtenerPorId(id) {
  const pedido = await prisma.pedido.findUnique({
    where: { id },
    include: { items: true, pago: true },
  });

  if (!pedido) {
    const error = new Error("Pedido no encontrado");
    error.status = 404;
    throw error;
  }
  return pedido;
}

module.exports = { crearPedido, confirmarPago, actualizarEstado, listarPedidosCliente, listarTodos, obtenerPorId };