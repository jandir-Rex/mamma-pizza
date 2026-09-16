function errorHandler(err, req, res, next) {
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
  if (err.name === "PrismaClientValidationError" || err.name === "PrismaClientKnownRequestError") {
    return res.status(400).json({ error: "Los datos enviados no son válidos" });
  }

  const status = err.status || 500;
  const message = err.status ? err.message : "Error interno del servidor";

  res.status(status).json({ error: message });
}

module.exports = errorHandler;