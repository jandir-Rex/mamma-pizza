const { z } = require("zod");

const crearMesaSchema = z.object({
  numero: z.number().int().positive("El número de mesa debe ser positivo"),
  capacidad: z.number().int().positive().optional(),
});

const actualizarMesaSchema = z.object({
  numero: z.number().int().positive().optional(),
  capacidad: z.number().int().positive().optional(),
});

module.exports = { crearMesaSchema, actualizarMesaSchema };