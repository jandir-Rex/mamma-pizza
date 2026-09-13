const prisma = require("../../config/prisma");

// ---------- CATEGORÍAS ----------

async function crearCategoria({ nombre }) {
    return prisma.categoria.create({ data: { nombre } });
}

async function listarCategorias() {
    return prisma.categoria.findMany({ orderBy: { nombre: "asc" } });
}

// ---------- PRODUCTOS ----------

async function crearProducto({ nombre, descripcion, categoriaId, imagenUrl, variantes }) {
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
        include: { variantes: true, categoria: true },
    });
}

async function listarMenu() {
    const hoy = new Date();
    hoy.setHours(0, 0, 0, 0);

    const productos = await prisma.producto.findMany({
        where: { disponible: true },
        include: {
            categoria: true,
            variantes: {
                include: {
                    disponibilidad: {
                        where: { fecha: hoy },
                    },
                },
            },
        },
        orderBy: { nombre: "asc" },
    });

    // Aplana la info de disponibilidad de hoy junto a cada variante
    return productos.map((p) => ({
        ...p,
        variantes: p.variantes.map((v) => {
            const stockHoy = v.disponibilidad[0];
            return {
                id: v.id,
                tamano: v.tamano,
                precio: v.precio,
                disponible: v.disponible,
            };
        }),
    }));
}

async function obtenerProductoPorId(id) {
    const producto = await prisma.producto.findUnique({
        where: { id },
        include: { categoria: true, variantes: true },
    });

    if (!producto) {
        const error = new Error("Producto no encontrado");
        error.status = 404;
        throw error;
    }

    return producto;
}

async function actualizarProducto(id, datos) {
    await obtenerProductoPorId(id); // valida que exista

    return prisma.producto.update({
        where: { id },
        data: datos,
        include: { categoria: true, variantes: true },
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
    listarCategorias,
    crearProducto,
    listarMenu,
    obtenerProductoPorId,
    actualizarProducto,
    desactivarProducto,
    actualizarDisponibilidadVariante,
};