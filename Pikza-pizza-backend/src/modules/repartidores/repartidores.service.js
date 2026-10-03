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
  const [repartidores, cargas] = await Promise.all([
    prisma.repartidor.findMany({
      where: { disponible: true, latActual: { not: null }, lngActual: { not: null } },
      include: { usuario: { select: { nombre: true, telefono: true } } },
    }),
    prisma.pedido.groupBy({
      by: ["repartidorId"],
      where: {
        repartidorId: { not: null },
        estado: { notIn: ["ENTREGADO", "CANCELADO"] },
      },
      _count: { _all: true },
    }),
  ]);
  const cargaPorRepartidor = new Map(
    cargas.map((carga) => [carga.repartidorId, carga._count._all]),
  );

  return repartidores
    .map((repartidor) => ({
      ...repartidor,
      pedidosActivos: cargaPorRepartidor.get(repartidor.id) ?? 0,
    }))
    .filter((repartidor) => repartidor.pedidosActivos < repartidor.capacidadPedidos);
}

async function encontrarMasCercano(lat, lng) {
  const [disponibles, cargas] = await Promise.all([
    prisma.repartidor.findMany({
      where: { disponible: true, latActual: { not: null }, lngActual: { not: null } },
      include: { usuario: { select: { nombre: true, telefono: true } } },
    }),
    prisma.pedido.groupBy({
      by: ["repartidorId"],
      where: {
        repartidorId: { not: null },
        estado: { notIn: ["ENTREGADO", "CANCELADO"] },
      },
      _count: { _all: true },
    }),
  ]);

  if (disponibles.length === 0) {
    const error = new Error("No hay repartidores disponibles en este momento");
    error.status = 404;
    throw error;
  }

  const cargaPorRepartidor = new Map(
    cargas.map((carga) => [carga.repartidorId, carga._count._all]),
  );
  const conCapacidad = disponibles
    .map((repartidor) => ({
      repartidor,
      pedidosActivos: cargaPorRepartidor.get(repartidor.id) ?? 0,
      distanciaKm: haversineKm(lat, lng, repartidor.latActual, repartidor.lngActual),
    }))
    .filter(({ repartidor, pedidosActivos }) => pedidosActivos < repartidor.capacidadPedidos);

  if (conCapacidad.length === 0) {
    const error = new Error("Todos los repartidores disponibles alcanzaron su capacidad de pedidos");
    error.status = 409;
    throw error;
  }

  const distanciaMaxima = Math.max(...conCapacidad.map(({ distanciaKm }) => distanciaKm));
  const conPuntaje = conCapacidad.map((candidato) => {
    const distanciaRelativa = distanciaMaxima === 0 ? 0 : candidato.distanciaKm / distanciaMaxima;
    const cargaRelativa = candidato.pedidosActivos / candidato.repartidor.capacidadPedidos;
    return {
      ...candidato,
      puntaje: (distanciaRelativa + cargaRelativa) / 2,
    };
  });
  conPuntaje.sort((a, b) =>
    a.puntaje - b.puntaje ||
    a.pedidosActivos - b.pedidosActivos ||
    a.distanciaKm - b.distanciaKm ||
    a.repartidor.id - b.repartidor.id
  );

  const mejor = conPuntaje[0];
  return {
    repartidor: mejor.repartidor,
    distanciaKm: Number(mejor.distanciaKm.toFixed(2)),
    pedidosActivos: mejor.pedidosActivos,
    capacidadPedidos: mejor.repartidor.capacidadPedidos,
    puntajeBalance: Number(mejor.puntaje.toFixed(4)),
  };
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