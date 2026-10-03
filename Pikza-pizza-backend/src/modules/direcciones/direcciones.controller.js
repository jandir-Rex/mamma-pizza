const { crearDireccionSchema } = require("./direcciones.validation");
const direccionesService = require("./direcciones.service");

async function crearDireccion(req, res, next) {
  try {
    const datos = crearDireccionSchema.parse(req.body);
    res.status(201).json(await direccionesService.crearDireccion(req.usuario.id, datos));
  } catch (err) {
    if (err.name === "ZodError") return res.status(400).json({ error: err.issues[0].message });
    next(err);
  }
}

async function listarPropias(req, res, next) {
  try {
    res.json(await direccionesService.listarPropias(req.usuario.id));
  } catch (err) {
    next(err);
  }
}

async function eliminarDireccion(req, res, next) {
  try {
    await direccionesService.eliminarDireccion(req.usuario.id, Number(req.params.id));
    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

module.exports = { crearDireccion, listarPropias, eliminarDireccion };