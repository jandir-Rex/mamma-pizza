const prisma = require("../../config/prisma");
const { haversineKm } = require("../../utils/geo");

async function obtenerPorUsuarioId(usuarioId) {
  const repartidor = await prisma.repartidor.findUnique({ where: { usuarioId } });
  if (!repartidor) {
    const error = new Error("No tienes un perfil de repartidor asociado");
    error.status = 404;
    throw error;
  }
  return repartidor;
}

async function actualizarUbicacion(usuarioId, lat, lng) {
  await obtenerPorUsuarioId(usuarioId);
  return prisma.repartidor.update({
    where: { usuarioId },
    data: { latActual: lat, lngActual: lng },
  });
}

async function actualizarDisponibilidad(usuarioId, disponible) {
  await obtenerPorUsuarioId(usuarioId);
  return prisma.repartidor.update({ where: { usuarioId }, data: { disponible } });
}

async function actualizarVehiculo(usuarioId, vehiculo) {
  await obtenerPorUsuarioId(usuarioId);
  return prisma.repartidor.update({ where: { usuarioId }, data: { vehiculo } });
}

async function listarTodos() {
  return prisma.repartidor.findMany({
    include: { usuario: { select: { nombre: true, telefono: true } } },
    orderBy: { id: "asc" },
  });
}

async function listarDisponibles() {
  return prisma.repartidor.findMany({
    where: { disponible: true, latActual: { not: null }, lngActual: { not: null } },
    include: { usuario: { select: { nombre: true, telefono: true } } },
  });
}

async function encontrarMasCercano(lat, lng) {
  const disponibles = await listarDisponibles();

  if (disponibles.length === 0) {
    const error = new Error("No hay repartidores disponibles en este momento");
    error.status = 404;
    throw error;
  }

  let mejor = null;
  let mejorDistancia = Infinity;

  for (const r of disponibles) {
    const distancia = haversineKm(lat, lng, r.latActual, r.lngActual);
    if (distancia < mejorDistancia) {
      mejorDistancia = distancia;
      mejor = r;
    }
  }

  return { repartidor: mejor, distanciaKm: Number(mejorDistancia.toFixed(2)) };
}

async function sugerirParaPedido(pedidoId) {
  const pedido = await prisma.pedido.findUnique({
    where: { id: pedidoId },
    include: { direccion: true },
  });

  if (!pedido) {
    const error = new Error("Pedido no encontrado");
    error.status = 404;
    throw error;
  }
  if (pedido.canal !== "DELIVERY" || !pedido.direccion) {
    const error = new Error("Este pedido no es de delivery o no tiene dirección");
    error.status = 400;
    throw error;
  }

  return encontrarMasCercano(pedido.direccion.lat, pedido.direccion.lng);
}

module.exports = {
  obtenerPorUsuarioId,
  actualizarUbicacion,
  actualizarDisponibilidad,
  actualizarVehiculo,
  listarTodos,
  listarDisponibles,
  sugerirParaPedido,
};