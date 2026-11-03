const prisma = require("../../config/prisma");

async function crearCategoria({ nombre, parentId = null, areaPreparacion = null }) {
  if (parentId !== null) {
    const padre = await prisma.categoria.findUnique({ where: { id: parentId } });
    if (!padre) {
      const error = new Error("La categorÃ­a principal indicada no existe");
      error.status = 400;
      throw error;
    }
    if (padre.parentId !== null) {
      const error = new Error("Las subcategorÃ­as solo pueden depender de una categorÃ­a principal");
      error.status = 400;
      throw error;
    }
  }

  return prisma.categoria.create({ data: { nombre, parentId, areaPreparacion } });
}

async function actualizarAreaCategoria(id, areaPreparacion) {
  const categoria = await prisma.categoria.findUnique({ where: { id } });
  if (!categoria) {
    const error = new Error("La categorÃ­a indicada no existe");
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
    const error = new Error("La categorÃ­a indicada no existe");
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
      const error = new Error("La categorÃ­a indicada no existe");
      error.status = 400;
      throw error;
    }
  }

  const { variantes, ...datosProducto } = datos;

  return prisma.$transaction(async (tx) => {
    if (Object.keys(datosProducto).length > 0) {
      await tx.producto.update({ where: { id }, data: datosProducto });
    }

    if (variantes) {
      const existentes = await tx.productoVariante.findMany({ where: { productoId: id } });
      const idsEnviados = variantes.filter((v) => v.id).map((v) => v.id);

      for (const v of variantes) {
        if (v.id) {
          if (!existentes.some((e) => e.id === v.id)) {
            const error = new Error(`La variante ${v.id} no pertenece a este producto`);
            error.status = 400;
            throw error;
          }
          await tx.productoVariante.update({
            where: { id: v.id },
            data: { tamano: v.tamano, precio: v.precio },
          });
        } else {
          await tx.productoVariante.create({
            data: { productoId: id, tamano: v.tamano, precio: v.precio },
          });
        }
      }

      // Variantes quitadas: se borran si no tienen historial; si tienen pedidos, se ocultan
      for (const e of existentes.filter((e) => !idsEnviados.includes(e.id))) {
        const usos = await tx.pedidoItem.count({ where: { productoVarianteId: e.id } });
        if (usos === 0) {
          await tx.disponibilidadDiaria.deleteMany({ where: { productoVarianteId: e.id } });
          await tx.productoVariante.delete({ where: { id: e.id } });
        } else {
          await tx.productoVariante.update({ where: { id: e.id }, data: { disponible: false } });
        }
      }
    }

    return tx.producto.findUnique({
      where: { id },
      include: { categoria: { include: { padre: true } }, variantes: true },
    });
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