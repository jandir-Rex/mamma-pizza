// src/middlewares/error.middleware.js
function errorHandler(err, req, res, next) {
  console.error("--- ERROR EN BACKEND ---");
  console.error(err);

  if (err.type === "entity.parse.failed") {
    return res.status(400).json({ error: "El cuerpo de la petición no es JSON válido" });
  }

  if (err.code === "P2002") {
    return res.status(409).json({ error: "Ya existe un registro con ese valor único" });
  }
  if (err.code === "P2003") {
    return res.status(400).json({ error: "Uno de los datos referenciados no existe" });
  }
  if (err.code === "P2025") {
    return res.status(404).json({ error: "Registro no encontrado" });
  }

  // Si Prisma tiene error de validación de campos, muestra el mensaje real
  if (err.name === "PrismaClientValidationError") {
    return res.status(400).json({ error: err.message.split("\n").slice(-2).join(" ") });
  }

  const status = err.status || 500;
  const message = err.message || "Error interno del servidor";

  res.status(status).json({ error: message });
}

module.exports = errorHandler;