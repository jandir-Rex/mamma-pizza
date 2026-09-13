const { z } = require("zod");

const itemSchema = z.object({
  productoVarianteId: z.number().int().positive(),
  cantidad: z.number().int().positive(),
  notas: z.string().optional(),
});

const crearPedidoSchema = z
  .object({
    canal: z.enum(["DELIVERY", "SALON"]),
    direccionId: z.number().int().positive().optional(),
    mesaId: z.number().int().positive().optional(),
    metodoPago: z.enum(["YAPE", "EFECTIVO", "TARJETA"]),
    items: z.array(itemSchema).min(1, "El pedido debe tener al menos un producto"),
  })
  .refine((data) => (data.canal === "DELIVERY" ? !!data.direccionId : !!data.mesaId), {
    message: "Delivery requiere direccionId; salón requiere mesaId",
  });

const actualizarEstadoSchema = z.object({
  estado: z.enum(["EN_PREPARACION", "EN_CAMINO", "ENTREGADO", "CANCELADO"]),
});

module.exports = { crearPedidoSchema, actualizarEstadoSchema };