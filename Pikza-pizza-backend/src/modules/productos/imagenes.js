// src/modules/productos/imagenes.js
// Subida de imágenes de productos desde archivo.
//
// - Recibe el archivo en memoria (máx. 5 MB) con multer.
// - Verifica el tipo REAL por la firma del archivo (no se confía en el nombre ni en el
//   mimetype que manda el navegador): solo JPG, PNG o WEBP.
// - Guarda en Cloudinary si existe CLOUDINARY_URL; si no, en disco (carpeta /uploads).
const fs = require("fs/promises");
const path = require("path");
const crypto = require("crypto");
const multer = require("multer");

// <raíz del backend>/uploads  (src/modules/productos -> ../../../uploads)
const UPLOADS_DIR = path.resolve(__dirname, "../../../uploads");
const CARPETA_PRODUCTOS = "productos";
const MAX_BYTES = 5 * 1024 * 1024;

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_BYTES, files: 1 },
});

/** Middleware: lee el campo "imagen" y responde 400 con mensaje claro si algo sale mal. */
function recibirImagen(req, res, next) {
  upload.single("imagen")(req, res, (err) => {
    if (!err) return next();
    if (err instanceof multer.MulterError) {
      const mensajes = {
        LIMIT_FILE_SIZE: "La imagen no puede superar los 5 MB",
        LIMIT_UNEXPECTED_FILE: 'Envía una sola imagen en el campo "imagen"',
      };
      return res.status(400).json({ error: mensajes[err.code] || "No se pudo procesar la imagen" });
    }
    next(err);
  });
}

/** Detecta JPG / PNG / WEBP por los primeros bytes. Devuelve null si no es ninguno. */
function detectarTipo(buf) {
  if (buf.length >= 3 && buf[0] === 0xff && buf[1] === 0xd8 && buf[2] === 0xff) {
    return { ext: "jpg", mime: "image/jpeg" };
  }
  if (
    buf.length >= 8 &&
    buf.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))
  ) {
    return { ext: "png", mime: "image/png" };
  }
  if (buf.length >= 12 && buf.toString("ascii", 0, 4) === "RIFF" && buf.toString("ascii", 8, 12) === "WEBP") {
    return { ext: "webp", mime: "image/webp" };
  }
  return null;
}

async function guardarEnDisco(buffer, tipo, req) {
  const carpeta = path.join(UPLOADS_DIR, CARPETA_PRODUCTOS);
  await fs.mkdir(carpeta, { recursive: true });

  // Nombre generado por nosotros: nunca se usa el nombre que manda el usuario.
  const nombre = `${crypto.randomUUID()}.${tipo.ext}`;
  await fs.writeFile(path.join(carpeta, nombre), buffer);

  // PUBLIC_URL: dirección pública del backend (ej. http://192.168.1.10:4000 o https://api.mipizzeria.com).
  // Si no existe, se usa la misma dirección con la que llegó la petición.
  const base = (process.env.PUBLIC_URL || `${req.protocol}://${req.get("host")}`).replace(/\/+$/, "");
  return `${base}/uploads/${CARPETA_PRODUCTOS}/${nombre}`;
}

function subirACloudinary(buffer) {
  let cloudinary;
  try {
    ({ v2: cloudinary } = require("cloudinary"));
  } catch {
    const error = new Error("Cloudinary está configurado pero no instalado. Ejecuta: npm install cloudinary");
    error.status = 500;
    throw error;
  }

  return new Promise((resolve, reject) => {
    cloudinary.uploader
      .upload_stream(
        {
          folder: "mamma-pizza/productos",
          resource_type: "image",
          // Evita guardar fotos gigantes: máx. 1200 px de ancho y calidad automática.
          transformation: [{ width: 1200, crop: "limit", quality: "auto" }],
        },
        (err, resultado) => {
          if (err || !resultado) {
            const error = new Error("No se pudo subir la imagen al almacenamiento");
            error.status = 502;
            return reject(error);
          }
          resolve(resultado.secure_url);
        }
      )
      .end(buffer);
  });
}

/** Valida el archivo y lo guarda. Devuelve la URL pública de la imagen. */
async function guardarImagen(buffer, req) {
  const tipo = detectarTipo(buffer);
  if (!tipo) {
    const error = new Error("Solo se permiten imágenes JPG, PNG o WEBP");
    error.status = 400;
    throw error;
  }

  if (process.env.CLOUDINARY_URL) return subirACloudinary(buffer);
  return guardarEnDisco(buffer, tipo, req);
}

module.exports = { UPLOADS_DIR, MAX_BYTES, recibirImagen, detectarTipo, guardarImagen };