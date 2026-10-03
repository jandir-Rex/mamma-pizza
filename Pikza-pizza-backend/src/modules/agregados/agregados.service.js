const prisma = require("../../config/prisma");

async function crearAgregado({ nombre, precios }) {
  const existente = await prisma.agregado.findUnique({ where: { nombre } });
  if (existente) {
    const error = new Error("Ya existe un agregado con ese nombre");
    error.status = 409;
    throw error;
  }

  return prisma.agregado.create({
    data: {
      nombre,
      precios: { create: precios.map((p) => ({ tamano: p.tamano, precio: p.precio })) },
    },
    include: { precios: true },
  });
}

async function listarAgregados() {
  return prisma.agregado.findMany({
    where: { disponible: true },
    include: { precios: true },
    orderBy: { nombre: "asc" },
  });
}

async function obtenerPorId(id) {
  const agregado = await prisma.agregado.findUnique({
    where: { id },
    include: { precios: true },
  });
  if (!agregado) {
    const error = new Error("Agregado no encontrado");
    error.status = 404;
    throw error;
  }
  return agregado;
}

async function actualizarAgregado(id, datos) {
  await obtenerPorId(id);
  return prisma.agregado.update({ where: { id }, data: datos });
}

async function actualizarPrecio(id, tamano, precio) {
  await obtenerPorId(id);

  return prisma.agregadoPrecio.upsert({
    where: { agregadoId_tamano: { agregadoId: id, tamano } },
    update: { precio },
    create: { agregadoId: id, tamano, precio },
  });
}

module.exports = { crearAgregado, listarAgregados, obtenerPorId, actualizarAgregado, actualizarPrecio };