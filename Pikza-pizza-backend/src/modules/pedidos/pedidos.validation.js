// src/modules/pedidos/pedidos.validation.js
const { z } = require("zod");

const agregadoItemSchema = z.object({
  agregadoId: z.number().int().positive(),
});

const MAX_CANTIDAD_POR_ITEM = 50;
const MAX_ITEMS_POR_PEDIDO = 30;

const itemSchema = z.object({
  productoVarianteId: z.number().int().positive(),
  cantidad: z.number().int().positive().max(MAX_CANTIDAD_POR_ITEM, `Máximo ${MAX_CANTIDAD_POR_ITEM} unidades por producto`),
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
    // Efectivo: con cuánto va a pagar el cliente (para llevar el vuelto)
    pagaCon: z.number().positive().max(10000).optional(),
    items: z.array(itemSchema)
      .min(1, "El pedido debe tener al menos un producto")
      .max(MAX_ITEMS_POR_PEDIDO, `Máximo ${MAX_ITEMS_POR_PEDIDO} productos distintos por pedido`),
  })
  .refine((data) => (data.canal === "DELIVERY" ? !!data.direccionId : true), {
    message: "Delivery requiere direccionId",
  });

const agregarItemsSchema = z.object({
  items: z.array(itemSchema)
    .min(1, "Debe agregar al menos un producto a la comanda")
    .max(MAX_ITEMS_POR_PEDIDO, `Máximo ${MAX_ITEMS_POR_PEDIDO} productos distintos por operación`),
});

const confirmarPagoSchema = z.object({
  metodo: z.enum(["YAPE", "EFECTIVO", "TARJETA"]),
});

const actualizarEstadoSchema = z.object({
  estado: z.enum(["EN_PREPARACION", "EN_CAMINO", "ENTREGADO", "CANCELADO"]),
});

// Código de confirmación de entrega: exactamente 4 dígitos
const entregarConCodigoSchema = z.object({
  codigo: z
    .string()
    .trim()
    .regex(/^\d{4}$/, "El código debe tener exactamente 4 dígitos"),
});

// regenerar = true genera un código nuevo además de poner los intentos en 0
const resetearCodigoSchema = z.object({
  regenerar: z.boolean().optional().default(false),
});

// Captura de Yape: el archivo va por multipart, aquí se valida el texto
const subirComprobanteSchema = z.object({
  yapeNombre: z.string().trim().min(2, "Indica el nombre de quien yapeó").max(80),
});

const rechazarComprobanteSchema = z.object({
  motivo: z.string().trim().min(3, "Indica el motivo del rechazo").max(200),
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
  entregarConCodigoSchema,
  resetearCodigoSchema,
  subirComprobanteSchema,
  rechazarComprobanteSchema,
  listarPedidosQuerySchema,
  auditarPedidosQuerySchema,
};