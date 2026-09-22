const prisma = require("../../config/prisma");

async function crearDireccion(usuarioId, datos) {
  return prisma.direccion.create({ data: { usuarioId, ...datos } });
}

async function listarPropias(usuarioId) {
  return prisma.direccion.findMany({ where: { usuarioId }, orderBy: { id: "desc" } });
}

async function eliminarDireccion(usuarioId, id) {
  const direccion = await prisma.direccion.findUnique({ where: { id } });
  if (!direccion || direccion.usuarioId !== usuarioId) {
    const error = new Error("Dirección no encontrada");
    error.status = 404;
    throw error;
  }

  const pedidosActivos = await prisma.pedido.count({
    where: { direccionId: id, estado: { notIn: ["ENTREGADO", "CANCELADO"] } },
  });
  if (pedidosActivos > 0) {
    const error = new Error("No se puede eliminar una dirección con pedidos activos");
    error.status = 409;
    throw error;
  }

  return prisma.direccion.delete({ where: { id } });
}

module.exports = { crearDireccion, listarPropias, eliminarDireccion };