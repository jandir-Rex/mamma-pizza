// src/types/pedido.ts

export type EstadoPedido =
  | "PENDIENTE_PAGO"
  | "CONFIRMADO"
  | "EN_PREPARACION"
  | "EN_CAMINO"
  | "ENTREGADO"
  | "CANCELADO";

export type Pedido = {
  id: number;
  codigo: string;
  canal: "DELIVERY" | "SALON";
  estado: EstadoPedido;
  total: number | string;
  createdAt: string;
  repartidorId?: number | null;
  repartidor?: { id: number; usuario?: { nombre: string } } | null;
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