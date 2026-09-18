
import { useState } from "react";
import api from "../services/api";

const TRANSICIONES_ESTADO = {
  CONFIRMADO: ["EN_PREPARACION", "CANCELADO"],
  EN_PREPARACION: ["EN_CAMINO", "ENTREGADO", "CANCELADO"],
  EN_CAMINO: ["ENTREGADO", "CANCELADO"],
};

const ETIQUETAS = {
  EN_PREPARACION: "En preparación",
  EN_CAMINO: "En camino",
  ENTREGADO: "Entregado",
  CANCELADO: "Cancelar pedido",
};

export default function PanelDetallePedido({ pedido, variantesMap, onCerrar, onActualizado }) {
  const [cargando, setCargando] = useState(false);
  const [error, setError] = useState("");

  if (!pedido) {
    return (
      <div className="hidden lg:flex w-80 items-center justify-center text-gray-400 text-sm border-l">
        Selecciona un pedido para ver el detalle
      </div>
    );
  }

  async function ejecutar(accion) {
    setError("");
    setCargando(true);
    try {
      let data;
      if (accion === "confirmar-pago") {
        ({ data } = await api.patch(`/pedidos/${pedido.id}/confirmar-pago`));
      } else if (accion === "asignar-repartidor") {
        const sugerido = await api.get(`/repartidores/sugerido/${pedido.id}`);
        ({ data } = await api.patch(`/pedidos/${pedido.id}/asignar-repartidor`, {
          repartidorId: sugerido.data.repartidor.id,
        }));
      } else {
        ({ data } = await api.patch(`/pedidos/${pedido.id}/estado`, { estado: accion }));
      }
      onActualizado(data);
    } catch (err) {
      setError(err.response?.data?.error || "No se pudo completar la acción");
    } finally {
      setCargando(false);
    }
  }

  const transicionesDisponibles = (TRANSICIONES_ESTADO[pedido.estado] || []).filter(
    (e) => e !== "EN_CAMINO" || pedido.canal === "DELIVERY"
  );

  return (
    <div className="w-full lg:w-80 bg-white border-l p-4 overflow-y-auto">
      <div className="flex justify-between items-start mb-4">
        <div>
          <h2 className="font-bold text-dark">{pedido.codigo}</h2>
          <span className="text-xs text-gray-400">{pedido.canal}</span>
        </div>
        <button onClick={onCerrar} className="text-gray-400 hover:text-dark">✕</button>
      </div>

      {error && (
        <div className="bg-red-50 text-danger text-xs rounded-md p-2 mb-3">{error}</div>
      )}

      <div className="mb-4">
        <h3 className="text-xs font-semibold text-gray-400 uppercase mb-2">Productos</h3>
        {pedido.items.map((item) => {
          const info = variantesMap[item.productoVarianteId];
          return (
            <div key={item.id} className="text-sm mb-2">
              <div className="flex justify-between">
                <span>
                  {item.cantidad}x {info ? `${info.nombre} (${info.tamano})` : `Producto #${item.productoVarianteId}`}
                </span>
                <span>S/. {Number(item.precioUnitario * item.cantidad).toFixed(2)}</span>
              </div>
              {item.notas && <p className="text-xs text-gray-400 italic">"{item.notas}"</p>}
            </div>
          );
        })}
      </div>

      <div className="flex justify-between font-bold text-dark border-t pt-2 mb-4">
        <span>Total</span>
        <span>S/. {Number(pedido.total).toFixed(2)}</span>
      </div>

      <div className="mb-4">
        <h3 className="text-xs font-semibold text-gray-400 uppercase mb-2">Pago</h3>
        <p className="text-sm">
          {pedido.pago?.metodo} — {pedido.pago?.estado === "pagado" ? "✅ Pagado" : "⏳ Pendiente"}
        </p>
      </div>

      <div className="space-y-2">
        {pedido.estado === "PENDIENTE_PAGO" && (
          <button
            disabled={cargando}
            onClick={() => ejecutar("confirmar-pago")}
            className="w-full bg-success text-white text-sm rounded-md py-2 disabled:opacity-60"
          >
            Confirmar recepción de pago
          </button>
        )}

        {transicionesDisponibles
          .filter((e) => e !== "CANCELADO")
          .map((estado) => (
            <button
              key={estado}
              disabled={cargando}
              onClick={() => ejecutar(estado)}
              className="w-full bg-primary text-white text-sm rounded-md py-2 disabled:opacity-60"
            >
              {ETIQUETAS[estado]}
            </button>
          ))}

        {pedido.canal === "DELIVERY" &&
          ["CONFIRMADO", "EN_PREPARACION"].includes(pedido.estado) &&
          !pedido.repartidorId && (
            <button
              disabled={cargando}
              onClick={() => ejecutar("asignar-repartidor")}
              className="w-full bg-dark text-white text-sm rounded-md py-2 disabled:opacity-60"
            >
              Asignar repartidor más cercano
            </button>
          )}

        {transicionesDisponibles.includes("CANCELADO") && (
          <button
            disabled={cargando}
            onClick={() => ejecutar("CANCELADO")}
            className="w-full border border-danger text-danger text-sm rounded-md py-2 disabled:opacity-60"
          >
            Cancelar pedido
          </button>
        )}
      </div>
    </div>
  );
}