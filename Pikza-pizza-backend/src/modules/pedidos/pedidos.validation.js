// src/modules/pedidos/pedidos.validation.js
const { z } = require("zod");

const agregadoItemSchema = z.object({
  agregadoId: z.number().int().positive(),
});

const itemSchema = z.object({
  productoVarianteId: z.number().int().positive(),
  cantidad: z.number().int().positive(),
  notas: z.string().optional(),
  agregados: z.array(agregadoItemSchema).optional(),
});

const crearPedidoSchema = z
  .object({
    canal: z.enum(["DELIVERY", "SALON"]),
    direccionId: z.number().int().positive().optional(),
    mesaId: z.number().int().positive().nullable().optional(),
    clienteNombre: z.string().optional(),
    metodoPago: z.enum(["YAPE", "EFECTIVO", "TARJETA"]),
    items: z.array(itemSchema).min(1, "El pedido debe tener al menos un producto"),
  })
  .refine((data) => (data.canal === "DELIVERY" ? !!data.direccionId : true), {
    message: "Delivery requiere direccionId",
  });

const agregarItemsSchema = z.object({
  items: z.array(itemSchema).min(1, "Debe agregar al menos un producto a la comanda"),
});

const confirmarPagoSchema = z.object({
  metodo: z.enum(["YAPE", "EFECTIVO", "TARJETA"]),
});

const actualizarEstadoSchema = z.object({
  estado: z.enum(["EN_PREPARACION", "EN_CAMINO", "ENTREGADO", "CANCELADO"]),
});

const listarPedidosQuerySchema = z
  .object({
    desde: z.string().datetime({ offset: true }).optional(),
    hasta: z.string().datetime({ offset: true }).optional(),
  })
  .refine((query) => (query.desde === undefined) === (query.hasta === undefined), {
    message: "Debe indicar desde y hasta juntos",
  })
  .refine((query) => !query.desde || new Date(query.desde) < new Date(query.hasta), {
    message: "El rango de fechas no es válido",
  });

const auditarPedidosQuerySchema = listarPedidosQuerySchema.extend({
  pagina: z.coerce.number().int().min(1).default(1),
  limite: z.coerce.number().int().refine((value) => [10, 20, 50].includes(value), {
    message: "El límite debe ser 10, 20 o 50",
  }).default(10),
  busqueda: z.string().trim().max(100).optional(),
  estado: z.enum([
    "PENDIENTE_PAGO",
    "CONFIRMADO",
    "EN_PREPARACION",
    "EN_CAMINO",
    "ENTREGADO",
    "CANCELADO",
  ]).optional(),
  canal: z.enum(["SALON", "PARA_LLEVAR", "DELIVERY"]).optional(),
  pago: z.enum(["PAGADO", "PENDIENTE"]).optional(),
  iniciadoPor: z.union([
    z.literal("CLIENTE"),
    z.coerce.number().int().positive(),
  ]).optional(),
}).refine((query) => query.desde !== undefined && query.hasta !== undefined, {
  message: "La auditoría requiere un rango de fechas",
});

module.exports = {
  crearPedidoSchema,
  agregarItemsSchema,
  confirmarPagoSchema,
  actualizarEstadoSchema,
  listarPedidosQuerySchema,
  auditarPedidosQuerySchema,
};