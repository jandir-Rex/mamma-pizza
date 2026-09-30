const { z } = require("zod");

const registroSchema = z.object({
  nombre: z.string().min(2, "El nombre es muy corto"),
  email: z.string().email("Email inválido"),
  password: z.string().min(6, "La contraseña debe tener al menos 6 caracteres"),
  telefono: z.string().optional(),
});

const loginSchema = z.object({
  email: z.string().email("Email inválido"),
  password: z.string().min(1, "La contraseña es requerida"),
});

const staffSchema = z.object({
  nombre: z.string().min(2, "El nombre es muy corto"),
  email: z.string().email("Email inválido"),
  password: z.string().min(6, "La contraseña debe tener al menos 6 caracteres"),
  telefono: z.string().optional(),
  rol: z.enum(["ADMIN", "REPARTIDOR", "MOZO"], { message: "Rol de staff inválido" }),
});

const actualizarPerfilSchema = z.object({
  nombre: z.string().min(2, "El nombre es muy corto").optional(),
  telefono: z.string().optional(),
});

module.exports = { registroSchema, loginSchema, staffSchema, actualizarPerfilSchema };