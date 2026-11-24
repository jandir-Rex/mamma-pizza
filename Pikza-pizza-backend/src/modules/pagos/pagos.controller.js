// src/modules/pagos/pagos.controller.js
const { configPagoSchema } = require("./pagos.validation");
const pagosService = require("./pagos.service");

function manejarZodError(err, res, next) {
  if (err.name === "ZodError") {
    return res.status(400).json({ error: err.issues[0].message });
  }
  next(err);
}

// GET /config -> configuración completa para el panel de administración
async function obtenerConfig(req, res, next) {
  try {
    res.json(await pagosService.obtenerConfig());
  } catch (err) {
    next(err);
  }
}

// PUT /config  { yapeNumero, yapeTitular? }
async function actualizarConfig(req, res, next) {
  try {
    const datos = configPagoSchema.parse(req.body ?? {});
    res.json(await pagosService.actualizarConfig(datos));
  } catch (err) {
    manejarZodError(err, res, next);
  }
}

// POST /qr  (multipart: campo "imagen")
async function subirQr(req, res, next) {
  try {
    res.status(201).json(await pagosService.guardarQr(req.file));
  } catch (err) {
    next(err);
  }
}

// DELETE /qr
async function eliminarQr(req, res, next) {
  try {
    res.json(await pagosService.eliminarQr());
  } catch (err) {
    next(err);
  }
}

// GET /qr -> la imagen (pública: es la que ve el cliente para pagarte)
async function verQr(req, res, next) {
  try {
    const { mime, datos } = await pagosService.obtenerQr();
    res.set("Content-Type", mime);
    // La URL lleva ?v=<versión>, así que puede cachearse sin riesgo de mostrar un QR viejo
    res.set("Cache-Control", "public, max-age=3600");
    res.send(Buffer.from(datos));
  } catch (err) {
    next(err);
  }
}

module.exports = { obtenerConfig, actualizarConfig, subirQr, eliminarQr, verQr };