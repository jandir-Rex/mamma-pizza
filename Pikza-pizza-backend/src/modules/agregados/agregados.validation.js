const { z } = require("zod");

const precioSchema = z.object({
  tamano: z.string().min(1, "El tamaño es requerido"),
  precio: z.number().positive("El precio debe ser mayor a 0"),
});

const crearAgregadoSchema = z.object({
  nombre: z.string().min(1, "El nombre es requerido"),
  precios: z.array(precioSchema).min(1, "Debe tener al menos un precio por tamaño"),
});

const actualizarAgregadoSchema = z.object({
  nombre: z.string().min(1).optional(),
  disponible: z.boolean().optional(),
});

const actualizarPrecioSchema = z.object({
  tamano: z.string().min(1),
  precio: z.number().positive(),
});

module.exports = { crearAgregadoSchema, actualizarAgregadoSchema, actualizarPrecioSchema };