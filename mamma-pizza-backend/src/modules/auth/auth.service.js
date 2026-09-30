const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const prisma = require("../../config/prisma");
const { jwtSecret } = require("../../config/env");

async function registrar({ nombre, email, password, telefono }) {
  const existente = await prisma.usuario.findUnique({ where: { email } });
  if (existente) {
    const error = new Error("Ese email ya está registrado");
    error.status = 409;
    throw error;
  }

  const passwordHash = await bcrypt.hash(password, 10);

  const usuario = await prisma.usuario.create({
    data: { nombre, email, passwordHash, telefono, rol: "CLIENTE" },
  });

  return generarRespuesta(usuario);
}

async function crearStaff({ nombre, email, password, telefono, rol }) {
  const existente = await prisma.usuario.findUnique({ where: { email } });
  if (existente) {
    const error = new Error("Ese email ya está registrado");
    error.status = 409;
    throw error;
  }

  const passwordHash = await bcrypt.hash(password, 10);

  const usuario = await prisma.usuario.create({
    data: { nombre, email, passwordHash, telefono, rol },
  });

  if (rol === "REPARTIDOR") {
    await prisma.repartidor.create({ data: { usuarioId: usuario.id } });
  }

  return generarRespuesta(usuario);
}

async function login({ email, password }) {
  const usuario = await prisma.usuario.findUnique({ where: { email } });
  if (!usuario) {
    const error = new Error("Credenciales inválidas");
    error.status = 401;
    throw error;
  }

  const passwordValida = await bcrypt.compare(password, usuario.passwordHash);
  if (!passwordValida) {
    const error = new Error("Credenciales inválidas");
    error.status = 401;
    throw error;
  }

  return generarRespuesta(usuario);
}

async function actualizarPerfil(usuarioId, datos) {
  const usuario = await prisma.usuario.update({
    where: { id: usuarioId },
    data: datos,
  });

  return {
    id: usuario.id,
    nombre: usuario.nombre,
    email: usuario.email,
    telefono: usuario.telefono,
    rol: usuario.rol,
  };
}

function generarRespuesta(usuario) {
  const token = jwt.sign(
    { id: usuario.id, rol: usuario.rol },
    jwtSecret,
    { expiresIn: "7d" }
  );

  return {
    token,
    usuario: {
      id: usuario.id,
      nombre: usuario.nombre,
      email: usuario.email,
      rol: usuario.rol,
    },
  };
}

module.exports = { registrar, login, crearStaff, actualizarPerfil };