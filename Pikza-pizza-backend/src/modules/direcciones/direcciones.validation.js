const { z } = require("zod");

const crearDireccionSchema = z.object({
  zona: z.string().min(2, "Ingresa una dirección válida"),
  referencia: z.string().optional(),
  lat: z.number(),
  lng: z.number(),
});

module.exports = { crearDireccionSchema };