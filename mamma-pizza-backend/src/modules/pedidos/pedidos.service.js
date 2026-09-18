const prisma = require("../../config/prisma");
const { emitPedidoNuevo, emitPedidoActualizado } = require("../../sockets");

function generarCodigo() {
  return `PZ-${Date.now().toString(36).toUpperCase()}`;
}

const TRANSICIONES_VALIDAS = {
  PENDIENTE_PAGO: ["CONFIRMADO", "CANCELADO"],
  CONFIRMADO: ["EN_PREPARACION", "CANCELADO"],
  EN_PREPARACION: ["EN_CAMINO", "ENTREGADO", "CANCELADO"],
  EN_CAMINO: ["ENTREGADO", "CANCELADO"],
  ENTREGADO: [],
  CANCELADO: [],
};

async function crearPedido(clienteId, rolSolicitante, datos) {
  const { canal, direccionId, mesaId, metodoPago, items } = datos;

  if (rolSolicitante === "MOZO" && canal !== "SALON") {
    const error = new Error("El mozo solo puede registrar pedidos de salón");
    error.status = 403;
    throw error;
  }

  if (canal === "DELIVERY") {
    const direccion = await prisma.direccion.findUnique({ where: { id: direccionId } });
    if (!direccion) {
      const error = new Error("La dirección indicada no existe");
      error.status = 400;
      throw error;
    }
    if (direccion.usuarioId !== clienteId) {
      const error = new Error("Esa dirección no pertenece a tu cuenta");
      error.status = 403;
      throw error;
    }
  }

  if (canal === "SALON") {
    const mesa = await prisma.mesa.findUnique({ where: { id: mesaId } });
    if (!mesa) {
      const error = new Error("La mesa indicada no existe");
      error.status = 400;
      throw error;
    }
  }

  const pedido = await prisma.$transaction(async (tx) => {
    let subtotal = 0;
    const itemsParaCrear = [];

    for (const item of items) {
      const filas = await tx.$queryRaw`
        SELECT pv.id, pv.precio, pv.tamano, pv.disponible AS variante_disponible, p.disponible AS producto_disponible
        FROM producto_variantes pv
        JOIN productos p ON p.id = pv."productoId"
        WHERE pv.id = ${item.productoVarianteId}
        FOR UPDATE
      `;
      const variante = filas[0];

      if (!variante) {
        const error = new Error(`La variante ${item.productoVarianteId} no existe`);
        error.status = 404;
        throw error;
      }

      if (!variante.variante_disponible || !variante.producto_disponible) {
        const error = new Error("Uno de los productos elegidos ya no está disponible");
        error.status = 409;
        throw error;
      }

      let precioUnitario = Number(variante.precio);
      const agregadosParaCrear = [];

      if (item.agregados && item.agregados.length > 0) {
        for (const ag of item.agregados) {
          const agregado = await tx.agregado.findUnique({
            where: { id: ag.agregadoId },
            include: { precios: { where: { tamano: variante.tamano } } },
          });

          if (!agregado || !agregado.disponible) {
            const error = new Error("Uno de los agregados elegidos ya no está disponible");
            error.status = 409;
            throw error;
          }

          const precioAgregado = agregado.precios[0];
          if (!precioAgregado) {
            const error = new Error(`El agregado "${agregado.nombre}" no tiene precio para el tamaño "${variante.tamano}"`);
            error.status = 400;
            throw error;
          }

          const precioAg = Number(precioAgregado.precio);
          precioUnitario += precioAg;
          agregadosParaCrear.push({ agregadoId: agregado.id, precioUnitario: precioAg });
        }
      }

      subtotal += precioUnitario * item.cantidad;

      itemsParaCrear.push({
        productoVarianteId: item.productoVarianteId,
        cantidad: item.cantidad,
        precioUnitario,
        notas: item.notas,
        agregados: agregadosParaCrear.length > 0 ? { create: agregadosParaCrear } : undefined,
      });
    }

    return tx.pedido.create({
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
      include: { items: { include: { agregados: true } }, pago: true },
    });
  });

  emitPedidoNuevo(pedido);
  return pedido;
}

async function confirmarPago(pedidoId) {
  const pedido = await prisma.$transaction(async (tx) => {
    const actual = await tx.pedido.findUnique({ where: { id: pedidoId } });

    if (!actual) {
      const error = new Error("Pedido no encontrado");
      error.status = 404;
      throw error;
    }
    if (actual.estado !== "PENDIENTE_PAGO") {
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

  emitPedidoActualizado(pedido);
  return pedido;
}

async function actualizarEstado(pedidoId, nuevoEstado) {
  const resultado = await prisma.$transaction(async (tx) => {
    const pedido = await tx.pedido.findUnique({ where: { id: pedidoId } });
    if (!pedido) {
      const error = new Error("Pedido no encontrado");
      error.status = 404;
      throw error;
    }

    const permitidos = TRANSICIONES_VALIDAS[pedido.estado] || [];
    if (!permitidos.includes(nuevoEstado)) {
      const error = new Error(`No se puede pasar de "${pedido.estado}" a "${nuevoEstado}"`);
      error.status = 409;
      throw error;
    }

    if (nuevoEstado === "EN_CAMINO" && pedido.canal !== "DELIVERY") {
      const error = new Error('El estado "EN_CAMINO" solo aplica a pedidos de delivery');
      error.status = 400;
      throw error;
    }

    const actualizado = await tx.pedido.update({
      where: { id: pedidoId },
      data: { estado: nuevoEstado },
    });

    if ((nuevoEstado === "ENTREGADO" || nuevoEstado === "CANCELADO") && pedido.repartidorId) {
      await tx.repartidor.update({ where: { id: pedido.repartidorId }, data: { disponible: true } });
    }

    return actualizado;
  });

  emitPedidoActualizado(resultado);
  return resultado;
}

async function asignarRepartidor(pedidoId, repartidorId) {
  const resultado = await prisma.$transaction(async (tx) => {
    const pedido = await tx.pedido.findUnique({ where: { id: pedidoId } });
    if (!pedido) {
      const error = new Error("Pedido no encontrado");
      error.status = 404;
      throw error;
    }
    if (pedido.canal !== "DELIVERY") {
      const error = new Error("Solo los pedidos de delivery necesitan repartidor");
      error.status = 400;
      throw error;
    }
    if (!["CONFIRMADO", "EN_PREPARACION"].includes(pedido.estado)) {
      const error = new Error("Solo se puede asignar repartidor a un pedido confirmado o en preparación");
      error.status = 409;
      throw error;
    }

    const repartidor = await tx.repartidor.findUnique({ where: { id: repartidorId } });
    if (!repartidor) {
      const error = new Error("Repartidor no encontrado");
      error.status = 404;
      throw error;
    }
    if (!repartidor.disponible) {
      const error = new Error("Ese repartidor ya no está disponible");
      error.status = 409;
      throw error;
    }

    await tx.repartidor.update({ where: { id: repartidorId }, data: { disponible: false } });

    return tx.pedido.update({
      where: { id: pedidoId },
      data: { repartidorId },
      include: { items: true, pago: true },
    });
  });

  emitPedidoActualizado(resultado);
  return resultado;
}

async function listarPedidosCliente(clienteId) {
  return prisma.pedido.findMany({
    where: { clienteId },
    include: { items: { include: { agregados: true } }, pago: true },
    orderBy: { createdAt: "desc" },
  });
}

async function listarTodos() {
  return prisma.pedido.findMany({
    include: {
      items: { include: { agregados: true } },
      pago: true,
      cliente: { select: { nombre: true, telefono: true } },
    },
    orderBy: { createdAt: "desc" },
  });
}

async function obtenerPorId(id) {
  const pedido = await prisma.pedido.findUnique({
    where: { id },
    include: { items: { include: { agregados: true } }, pago: true },
  });

  if (!pedido) {
    const error = new Error("Pedido no encontrado");
    error.status = 404;
    throw error;
  }
  return pedido;
}

module.exports = {
  crearPedido,
  confirmarPago,
  actualizarEstado,
  asignarRepartidor,
  listarPedidosCliente,
  listarTodos,
  obtenerPorId,
};