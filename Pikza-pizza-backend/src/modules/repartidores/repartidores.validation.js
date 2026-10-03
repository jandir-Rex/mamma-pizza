const { z } = require("zod");

const ubicacionSchema = z.object({
  lat: z.number(),
  lng: z.number(),
});

const disponibilidadSchema = z.object({
  disponible: z.boolean(),
});

const vehiculoSchema = z.object({
  vehiculo: z.string().min(1),
});

module.exports = { ubicacionSchema, disponibilidadSchema, vehiculoSchema };