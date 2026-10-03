// src/modules/auth/auth.controller.js
const {
  registroSchema,
  loginSchema,
  staffSchema,
  actualizarUsuarioAdminSchema,
  actualizarPerfilSchema,
} = require("./auth.validation");
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

async function obtenerSesion(req, res, next) {
  try {
    const usuario = await authService.obtenerSesion(req.usuario.id);
    res.json(usuario);
  } catch (err) {
    next(err);
  }
}

async function crearStaff(req, res, next) {
  try {
    const datos = staffSchema.parse(req.body);
    const resultado = await authService.crearStaff(datos, req.usuario);
    res.status(201).json(resultado);
  } catch (err) {
    if (err.name === "ZodError") {
      return res.status(400).json({ error: err.issues[0].message });
    }
    next(err);
  }
}

async function actualizarPerfil(req, res, next) {
  try {
    const datos = actualizarPerfilSchema.parse(req.body);
    const usuario = await authService.actualizarPerfil(req.usuario.id, datos);
    res.json(usuario);
  } catch (err) {
    if (err.name === "ZodError") return res.status(400).json({ error: err.issues[0].message });
    next(err);
  }
}

async function listarUsuarios(req, res, next) {
  try {
    const usuarios = await authService.listarUsuarios(req.query);
    res.json(usuarios);
  } catch (err) {
    next(err);
  }
}

async function actualizarUsuarioAdmin(req, res, next) {
  try {
    const id = Number(req.params.id);
    const datos = actualizarUsuarioAdminSchema.parse(req.body);
    const actualizado = await authService.actualizarUsuarioPorAdmin(id, datos, req.usuario);
    res.json(actualizado);
  } catch (err) {
    if (err.name === "ZodError") return res.status(400).json({ error: err.issues[0].message });
    next(err);
  }
}

async function eliminarUsuario(req, res, next) {
  try {
    const id = Number(req.params.id);
    const resultado = await authService.eliminarUsuario(id, req.usuario);
    res.json(resultado);
  } catch (err) {
    next(err);
  }
}

module.exports = {
  registrar,
  login,
  obtenerSesion,
  crearStaff,
  actualizarPerfil,
  listarUsuarios,
  actualizarUsuarioAdmin,
  eliminarUsuario,
};