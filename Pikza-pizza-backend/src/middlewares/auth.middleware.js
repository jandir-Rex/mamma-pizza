const jwt = require("jsonwebtoken");
const { jwtSecret } = require("../config/env");
const prisma = require("../config/prisma");

async function verificarToken(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Token no proporcionado" });
  }

  const token = authHeader.split(" ")[1];

  let payload;
  try {
    payload = jwt.verify(token, jwtSecret);
  } catch {
    return res.status(401).json({ error: "Token inválido o expirado" });
  }

  if (!Number.isInteger(payload.id) || payload.id <= 0) {
    return res.status(401).json({ error: "Token inválido o expirado" });
  }

  try {
    const usuario = await prisma.usuario.findUnique({
      where: { id: payload.id },
      select: { id: true, rol: true, permisos: true },
    });
    if (!usuario) {
      return res.status(401).json({ error: "La cuenta asociada a esta sesión ya no existe" });
    }
    req.usuario = usuario;
    next();
  } catch (error) {
    next(error);
  }
}

module.exports = verificarToken;