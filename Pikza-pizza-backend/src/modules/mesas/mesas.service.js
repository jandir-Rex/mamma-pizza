// src/modules/mesas/mesas.service.js
const prisma = require("../../config/prisma");

function inicioDeHoy() {
  const hoy = new Date();
  hoy.setHours(0, 0, 0, 0);
  return hoy;
}

async function crearMesa({ numero, capacidad }) {
  const existente = await prisma.mesa.findUnique({ where: { numero } });
  if (existente) {
    const error = new Error(`Ya existe una mesa con el número ${numero}`);
    error.status = 409;
    throw error;
  }
  return prisma.mesa.create({ data: { numero, capacidad } });
}

// Solo busca pedidos abiertos de HOY
async function listarMesas() {
  const hoy = inicioDeHoy();

  const mesas = await prisma.mesa.findMany({
    orderBy: { numero: "asc" },
    include: {
      pedidos: {
        where: {
          estado: { notIn: ["ENTREGADO", "CANCELADO"] },
          createdAt: { gte: hoy }, // Solo pedidos de hoy
        },
        select: { id: true, codigo: true, total: true, estado: true },
        take: 1,
      },
    },
  });

  return mesas.map((m) => ({
    id: m.id,
    numero: m.numero,
    capacidad: m.capacidad,
    ocupada: m.pedidos.length > 0,
    pedidoActivo: m.pedidos[0] || null,
  }));
}

async function obtenerMesaPorId(id) {
  const mesa = await prisma.mesa.findUnique({ where: { id } });
  if (!mesa) {
    const error = new Error("Mesa no encontrada");
    error.status = 404;
    throw error;
  }
  return mesa;
}

async function actualizarMesa(id, datos) {
  await obtenerMesaPorId(id);
  return prisma.mesa.update({ where: { id }, data: datos });
}

async function eliminarMesa(id) {
  await obtenerMesaPorId(id);
  const pedidosActivos = await prisma.pedido.count({
    where: { mesaId: id, estado: { notIn: ["ENTREGADO", "CANCELADO"] } },
  });
  if (pedidosActivos > 0) {
    const error = new Error("No se puede eliminar una mesa con pedidos activos");
    error.status = 409;
    throw error;
  }
  return prisma.mesa.delete({ where: { id } });
}

async function estadoMesas() {
  const hoy = inicioDeHoy();

  const mesas = await prisma.mesa.findMany({
    orderBy: { numero: "asc" },
    include: {
      pedidos: {
        where: {
          estado: { notIn: ["ENTREGADO", "CANCELADO"] },
          createdAt: { gte: hoy }, // Solo pedidos de hoy
        },
        select: { id: true, codigo: true, total: true, estado: true },
      },
    },
  });

  return mesas.map((m) => ({
    id: m.id,
    numero: m.numero,
    capacidad: m.capacidad,
    ocupada: m.pedidos.length > 0,
    pedidoActivo: m.pedidos[0] || null,
  }));
}

module.exports = {
  crearMesa,
  listarMesas,
  obtenerMesaPorId,
  actualizarMesa,
  eliminarMesa,
  estadoMesas,
};