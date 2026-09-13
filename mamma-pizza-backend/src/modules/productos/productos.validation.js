const { z } = require("zod");

const varianteSchema = z.object({
  tamano: z.string().min(1, "El tamaño es requerido"),
  precio: z.number().positive("El precio debe ser mayor a 0"),
});

const crearProductoSchema = z.object({
  nombre: z.string().min(2, "El nombre es muy corto"),
  descripcion: z.string().optional(),
  categoriaId: z.number().int().positive("Categoría inválida"),
  imagenUrl: z.string().url().optional(),
  variantes: z.array(varianteSchema).min(1, "Debe tener al menos una variante/tamaño"),
});

const actualizarProductoSchema = z.object({
  nombre: z.string().min(2).optional(),
  descripcion: z.string().optional(),
  categoriaId: z.number().int().positive().optional(),
  imagenUrl: z.string().url().optional(),
  disponible: z.boolean().optional(),
});

const crearCategoriaSchema = z.object({
  nombre: z.string().min(2, "El nombre es muy corto"),
});

const disponibilidadSchema = z.object({
  disponible: z.boolean(),
});

module.exports = {
  crearProductoSchema,
  actualizarProductoSchema,
  crearCategoriaSchema,
  disponibilidadSchema,
};