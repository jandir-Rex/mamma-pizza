const prisma = require("../../config/prisma");

async function crearCategoria({ nombre, parentId = null, areaPreparacion = null }) {
  if (parentId !== null) {
    const padre = await prisma.categoria.findUnique({ where: { id: parentId } });
    if (!padre) {
      const error = new Error("La categoría principal indicada no existe");
      error.status = 400;
      throw error;
    }
    if (padre.parentId !== null) {
      const error = new Error("Las subcategorías solo pueden depender de una categoría principal");
      error.status = 400;
      throw error;
    }
  }

  return prisma.categoria.create({ data: { nombre, parentId, areaPreparacion } });
}

async function actualizarAreaCategoria(id, areaPreparacion) {
  const categoria = await prisma.categoria.findUnique({ where: { id } });
  if (!categoria) {
    const error = new Error("La categoría indicada no existe");
    error.status = 404;
    throw error;
  }

  return prisma.categoria.update({
    where: { id },
    data: { areaPreparacion },
  });
}

async function listarCategorias() {
  return prisma.categoria.findMany({ orderBy: [{ parentId: "asc" }, { nombre: "asc" }] });
}

async function crearProducto({ nombre, descripcion, categoriaId, imagenUrl, variantes }) {
  const categoria = await prisma.categoria.findUnique({ where: { id: categoriaId } });
  if (!categoria) {
    const error = new Error("La categoría indicada no existe");
    error.status = 400;
    throw error;
  }

  return prisma.producto.create({
    data: {
      nombre,
      descripcion,
      categoriaId,
      imagenUrl,
      variantes: {
        create: variantes.map((v) => ({ tamano: v.tamano, precio: v.precio })),
      },
    },
    include: { variantes: true, categoria: { include: { padre: true } } },
  });
}

async function listarMenu() {
  const hoy = new Date();
  hoy.setHours(0, 0, 0, 0);

  const productos = await prisma.producto.findMany({
    where: { disponible: true },
    include: {
      categoria: { include: { padre: true } },
      variantes: {
        include: {
          disponibilidad: { where: { fecha: hoy } },
        },
      },
    },
    orderBy: { nombre: "asc" },
  });

  return productos.map((p) => ({
    ...p,
    variantes: p.variantes.map((v) => ({
      id: v.id,
      tamano: v.tamano,
      precio: v.precio,
      disponible: v.disponible,
    })),
  }));
}

async function obtenerProductoPorId(id) {
  const producto = await prisma.producto.findUnique({
    where: { id },
    include: { categoria: { include: { padre: true } }, variantes: true },
  });

  if (!producto) {
    const error = new Error("Producto no encontrado");
    error.status = 404;
    throw error;
  }

  return producto;
}

async function actualizarProducto(id, datos) {
  await obtenerProductoPorId(id);

  if (datos.categoriaId) {
    const categoria = await prisma.categoria.findUnique({ where: { id: datos.categoriaId } });
    if (!categoria) {
      const error = new Error("La categoría indicada no existe");
      error.status = 400;
      throw error;
    }
  }

  return prisma.producto.update({
    where: { id },
    data: datos,
    include: { categoria: { include: { padre: true } }, variantes: true },
  });
}

async function desactivarProducto(id) {
  await obtenerProductoPorId(id);

  return prisma.producto.update({
    where: { id },
    data: { disponible: false },
  });
}

async function actualizarDisponibilidadVariante(id, disponible) {
  const variante = await prisma.productoVariante.findUnique({ where: { id } });

  if (!variante) {
    const error = new Error("Variante no encontrada");
    error.status = 404;
    throw error;
  }

  return prisma.productoVariante.update({
    where: { id },
    data: { disponible },
  });
}

module.exports = {
  crearCategoria,
  actualizarAreaCategoria,
  listarCategorias,
  crearProducto,
  listarMenu,
  obtenerProductoPorId,
  actualizarProducto,
  desactivarProducto,
  actualizarDisponibilidadVariante,
};