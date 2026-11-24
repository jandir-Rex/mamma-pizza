// src/modules/pagos/pagos.validation.js
const { z } = require("zod");

// Número de Yape de Perú: 9 dígitos que empiezan con 9. Se aceptan espacios o guiones al escribirlo.
const yapeNumeroSchema = z.preprocess(
  (valor) => (typeof valor === "string" ? valor.replace(/[\s-]/g, "") : valor),
  z.string({ required_error: "Indica el número de Yape" }).regex(
    /^9\d{8}$/,
    "El número de Yape debe tener 9 dígitos y empezar con 9",
  ),
);

const configPagoSchema = z.object({
  yapeNumero: yapeNumeroSchema,
  yapeTitular: z
    .string()
    .trim()
    .max(80, "El nombre del titular es demasiado largo")
    .nullish()
    .transform((valor) => valor || null),
});

module.exports = { configPagoSchema };