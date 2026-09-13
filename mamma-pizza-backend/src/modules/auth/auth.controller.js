const { registroSchema, loginSchema } = require("./auth.validation");
const authService = require("./auth.service");

async function registrar(req, res, next) {
  try {
    const datos = registroSchema.parse(req.body);
    const resultado = await authService.registrar(datos);
    res.status(201).json(resultado);
  } catch (err) {
    if (err.name === "ZodError") {
      return res.status(400).json({ error: err.issues[0].message });
    }
    next(err);
  }
}

async function login(req, res, next) {
  try {
    const datos = loginSchema.parse(req.body);
    const resultado = await authService.login(datos);
    res.json(resultado);
  } catch (err) {
    if (err.name === "ZodError") {
      return res.status(400).json({ error: err.issues[0].message });
    }
    next(err);
  }
}

module.exports = { registrar, login };