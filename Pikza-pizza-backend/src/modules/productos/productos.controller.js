const {
  crearProductoSchema,
  actualizarProductoSchema,
  crearCategoriaSchema,
  actualizarAreaCategoriaSchema,
  disponibilidadSchema,
} = require("./productos.validation");
const productosService = require("./productos.service");
const imagenes = require("./imagenes");

function manejarZodError(err, res, next) {
  if (err.name === "ZodError") {
    return res.status(400).json({ error: err.issues[0].message });
  }
  next(err);
}

async function crearCategoria(req, res, next) {
  try {
    const datos = crearCategoriaSchema.parse(req.body);
    const categoria = await productosService.crearCategoria(datos);
    res.status(201).json(categoria);
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

async function listarCategorias(req, res, next) {
  try {
    const categorias = await productosService.listarCategorias();
    res.json(categorias);
  } catch (err) {
    next(err);
  }
}

async function actualizarAreaCategoria(req, res, next) {
  try {
    const id = Number(req.params.id);
    const { areaPreparacion } = actualizarAreaCategoriaSchema.parse(req.body);
    const categoria = await productosService.actualizarAreaCategoria(id, areaPreparacion);
    res.json(categoria);
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

async function crearProducto(req, res, next) {
  try {
    const datos = crearProductoSchema.parse(req.body);
    const producto = await productosService.crearProducto(datos);
    res.status(201).json(producto);
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

async function listarMenu(req, res, next) {
  try {
    const menu = await productosService.listarMenu();
    res.json(menu);
  } catch (err) {
    next(err);
  }
}

async function obtenerProducto(req, res, next) {
  try {
    const id = Number(req.params.id);
    const producto = await productosService.obtenerProductoPorId(id);
    res.json(producto);
  } catch (err) {
    next(err);
  }
}

async function actualizarProducto(req, res, next) {
  try {
    const id = Number(req.params.id);
    const datos = actualizarProductoSchema.parse(req.body);
    const producto = await productosService.actualizarProducto(id, datos);
    res.json(producto);
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

async function desactivarProducto(req, res, next) {
  try {
    const id = Number(req.params.id);
    await productosService.desactivarProducto(id);
    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

async function actualizarDisponibilidadVariante(req, res, next) {
  try {
    const id = Number(req.params.id);
    const { disponible } = disponibilidadSchema.parse(req.body);
    const variante = await productosService.actualizarDisponibilidadVariante(id, disponible);
    res.json(variante);
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

// Recibe el archivo (ya leído por el middleware recibirImagen) y devuelve su URL pública.
// El panel guarda esa URL en el campo imagenUrl del producto, igual que si la hubiera pegado.
async function subirImagen(req, res, next) {
  try {
    if (!req.file) {
      return res.status(400).json({ error: "Selecciona una imagen" });
    }
    const imagenUrl = await imagenes.guardarImagen(req.file.buffer, req);
    res.status(201).json({ imagenUrl });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  crearCategoria,
  listarCategorias,
  actualizarAreaCategoria,
  crearProducto,
  listarMenu,
  obtenerProducto,
  actualizarProducto,
  desactivarProducto,
  actualizarDisponibilidadVariante,
  subirImagen,
};