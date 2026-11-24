// src/modules/pagos/pagos.service.js
// Configuración de cobro con Yape: número, titular y QR.
// - Se guarda en la tabla config_pago (una sola fila, id = 1).
// - Si el admin todavía no configuró nada desde el panel, se usa YAPE_NUMERO / YAPE_TITULAR del .env.
const prisma = require("../../config/prisma");
const { detectarTipo } = require("../productos/imagenes");

const CONFIG_ID = 1;

function errorHttp(mensaje, status) {
  const error = new Error(mensaje);
  error.status = status;
  return error;
}

/** Configuración vigente + de dónde sale (panel, .env o sin configurar). */
async function obtenerConfig() {
  const fila = await prisma.configPago.findUnique({ where: { id: CONFIG_ID } });
  const usaPanel = Boolean(fila?.yapeNumero);
  const envNumero = process.env.YAPE_NUMERO || null;
  const envTitular = process.env.YAPE_TITULAR || null;

  return {
    yapeNumero: usaPanel ? fila.yapeNumero : envNumero,
    yapeTitular: usaPanel ? fila.yapeTitular : envTitular,
    tieneQr: Boolean(fila?.qrMime),
    // Cambia cada vez que se sube un QR nuevo: se usa para que las apps no muestren uno viejo en caché
    qrVersion: fila?.qrActualizadoEn ? fila.qrActualizadoEn.getTime() : null,
    origen: usaPanel ? "PANEL" : envNumero ? "ENV" : "SIN_CONFIGURAR",
    actualizadoEn: fila?.updatedAt ?? null,
  };
}

function baseUrl(req) {
  return (process.env.PUBLIC_URL || `${req.protocol}://${req.get("host")}`).replace(/\/+$/, "");
}

/** Lo que consumen las apps de los clientes (GET /pedidos/config-pago). */
async function configPublica(req) {
  const config = await obtenerConfig();
  return {
    yapeNumero: config.yapeNumero,
    yapeTitular: config.yapeTitular,
    yapeQrUrl: config.tieneQr ? `${baseUrl(req)}/api/pagos/qr?v=${config.qrVersion}` : null,
  };
}

async function actualizarConfig({ yapeNumero, yapeTitular }) {
  await prisma.configPago.upsert({
    where: { id: CONFIG_ID },
    create: { id: CONFIG_ID, yapeNumero, yapeTitular },
    update: { yapeNumero, yapeTitular },
  });
  return obtenerConfig();
}

async function guardarQr(archivo) {
  if (!archivo) throw errorHttp("Selecciona la imagen del QR", 400);
  const tipo = detectarTipo(archivo.buffer);
  if (!tipo) throw errorHttp("Solo se permiten imágenes JPG, PNG o WEBP", 400);

  const ahora = new Date();
  // Las operaciones del arreglo corren en orden: primero la fila de config, luego la imagen
  await prisma.$transaction([
    prisma.configPago.upsert({
      where: { id: CONFIG_ID },
      create: { id: CONFIG_ID, qrMime: tipo.mime, qrActualizadoEn: ahora },
      update: { qrMime: tipo.mime, qrActualizadoEn: ahora },
    }),
    prisma.configPagoQr.upsert({
      where: { configId: CONFIG_ID },
      create: { configId: CONFIG_ID, mime: tipo.mime, datos: archivo.buffer },
      update: { mime: tipo.mime, datos: archivo.buffer },
    }),
  ]);
  return obtenerConfig();
}

async function eliminarQr() {
  await prisma.$transaction([
    prisma.configPagoQr.deleteMany({ where: { configId: CONFIG_ID } }),
    prisma.configPago.updateMany({
      where: { id: CONFIG_ID },
      data: { qrMime: null, qrActualizadoEn: null },
    }),
  ]);
  return obtenerConfig();
}

async function obtenerQr() {
  const qr = await prisma.configPagoQr.findUnique({ where: { configId: CONFIG_ID } });
  if (!qr) throw errorHttp("Aún no hay un QR configurado", 404);
  return { mime: qr.mime, datos: qr.datos };
}

module.exports = {
  obtenerConfig,
  configPublica,
  actualizarConfig,
  guardarQr,
  eliminarQr,
  obtenerQr,
};