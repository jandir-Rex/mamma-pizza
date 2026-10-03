// src/modules/auth/auth.validation.js
const { z } = require("zod");

const telefonoSchema = z
  .string()
  .refine((telefono) => telefono === "" || /^\d{9}$/.test(telefono), {
    message: "El teléfono debe tener exactamente 9 dígitos",
  })
  .optional();

const registroSchema = z.object({
  nombre: z.string().min(2, "El nombre es muy corto"),
  email: z.string().email("Email inválido"),
  password: z.string().min(6, "La contraseña debe tener al menos 6 caracteres"),
  telefono: telefonoSchema,
});

const loginSchema = z.object({
  email: z.string().email("Email inválido"),
  password: z.string().min(1, "La contraseña es requerida"),
});

const staffSchema = z.object({
  nombre: z.string().min(2, "El nombre es muy corto"),
  email: z.string().email("Email inválido"),
  password: z.string().min(6, "La contraseña debe tener al menos 6 caracteres"),
  telefono: telefonoSchema,
  rol: z.enum(["ADMIN", "REPARTIDOR", "MOZO", "PERSONALIZADO"], { message: "Rol de staff inválido" }),
  permisos: z.array(z.string()).optional(),
  capacidadPedidos: z.number().int().min(1).optional(),
}).refine((datos) => datos.rol === "REPARTIDOR" || datos.capacidadPedidos === undefined, {
  message: "La capacidad de pedidos solo aplica al rol repartidor",
  path: ["capacidadPedidos"],
});

// Para que el Admin edite a cualquier usuario
const actualizarUsuarioAdminSchema = z.object({
  nombre: z.string().min(2).optional(),
  email: z.string().email().optional(),
  telefono: telefonoSchema,
  rol: z.enum(["ADMIN", "REPARTIDOR", "MOZO", "PERSONALIZADO", "CLIENTE"]).optional(),
  permisos: z.array(z.string()).optional(),
  password: z.string().min(6).optional(),
  capacidadPedidos: z.number().int().min(1).optional(),
});

// Para que cualquier usuario edite su propio perfil
const actualizarPerfilSchema = z.object({
  nombre: z.string().min(2, "El nombre es muy corto").optional(),
  telefono: telefonoSchema,
  dni: z.string().max(20, "El documento no puede exceder 20 caracteres").optional(),
  direccion: z.string().max(250, "La dirección no puede exceder 250 caracteres").optional(),
  ciudad: z.string().max(100, "La ciudad no puede exceder 100 caracteres").optional(),
  passwordActual: z.string().optional(),
  passwordNuevo: z.string().min(6).optional(),
});

module.exports = {
  registroSchema,
  loginSchema,
  staffSchema,
  actualizarUsuarioAdminSchema,
  actualizarPerfilSchema,
};