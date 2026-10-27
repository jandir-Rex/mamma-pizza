// src/types/pedido.ts

export type EstadoPedido =
  | "PENDIENTE_PAGO"
  | "CONFIRMADO"
  | "EN_PREPARACION"
  | "EN_CAMINO"
  | "ENTREGADO"
  | "CANCELADO";

// Debe coincidir con MAX_INTENTOS_CODIGO del backend
export const MAX_INTENTOS_CODIGO = 3;

export type Pedido = {
  id: number;
  codigo: string;
  canal: "DELIVERY" | "SALON";
  estado: EstadoPedido;
  total: number | string;
  createdAt: string;
  repartidorId?: number | null;
  repartidor?: { id: number; usuario?: { nombre: string } } | null;
  // --- Código de confirmación de entrega ---
  // codigoConfirmacion SOLO llega a admin/cliente; al repartidor el backend nunca se lo manda.
  codigoConfirmacion?: string | null;
  intentosCodigoFallidos?: number;
  confirmadoEn?: string | null;
  direccion?: {
    id: number;
    zona: string;
    referencia?: string | null;
    lat: number;
    lng: number;
  } | null;
  clienteId?: number;
  clienteNombre?: string | null; // 👈 Nombre del comensal presencial (ej: "PruebaTest")
  cliente?: { nombre: string; telefono?: string };
  atendidoPorId?: number | null;
  atendidoPor?: { id: number; nombre: string; rol?: string } | null; // 👈 Quien tomó la comanda
  historialAtencion?: {
    id: number;
    accion: "REGISTRO" | "CONTINUACION" | "FINALIZACION";
    usuarioNombre: string;
    usuarioRol: string;
    createdAt: string;
  }[];
  mesaId?: number | null;
  mesa?: { numero: number } | null;
  pago?: { metodo?: string; estado?: string } | null;
  items: PedidoItem[];
};

export type PedidoItem = {
  id: number;
  productoVarianteId: number;
  cantidad: number;
  precioUnitario: number | string;
  notas?: string | null;
};

export type VarianteInfo = {
  nombre: string;
  tamano: string;
  areaPreparacion?: "HORNO" | "BARRA";
};

// Respuesta de GET /pedidos/:id/sugerir-repartidores
export type CandidatoRepartidor = {
  repartidorId: number;
  nombre: string;
  vehiculo?: string | null;
  pedidosActivos: number;
  capacidadPedidos: number;
  distanciaKm: number | null; // null = el repartidor no tiene ubicación registrada
  score: number;
};

export type SugerenciaRepartidores = {
  pedidoId: number;
  candidatos: CandidatoRepartidor[];
  motivo?: string;
};

export type CanalOperativo = "SALON" | "PARA_LLEVAR" | "DELIVERY";

export function obtenerCanalOperativo(pedido: Pedido): CanalOperativo {
  if (pedido.canal === "DELIVERY") return "DELIVERY";
  if (pedido.mesa?.numero || pedido.mesaId) return "SALON";
  return "PARA_LLEVAR";
}

export const etiquetasEstado: Record<EstadoPedido, string> = {
  PENDIENTE_PAGO: "Pendiente de pago",
  CONFIRMADO: "Confirmado",
  EN_PREPARACION: "En preparación",
  EN_CAMINO: "En camino",
  ENTREGADO: "Entregado",
  CANCELADO: "Cancelado",
};

export function obtenerEtiquetaEstado(
  pedido: Pick<Pedido, "estado" | "canal">,
): string {
  if (pedido.estado === "ENTREGADO" && pedido.canal !== "DELIVERY") {
    return "Finalizado";
  }
  return etiquetasEstado[pedido.estado];
}

export function formatoPrecio(total: number | string) {
  return new Intl.NumberFormat("es-PE", {
    style: "currency",
    currency: "PEN",
  }).format(Number(total));
}