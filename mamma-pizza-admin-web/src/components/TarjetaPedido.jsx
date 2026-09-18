function tiempoTranscurrido(fechaISO) {
  const minutos = Math.floor((Date.now() - new Date(fechaISO).getTime()) / 60000);
  if (minutos < 1) return "Recién";
  if (minutos < 60) return `Hace ${minutos} min`;
  const horas = Math.floor(minutos / 60);
  return `Hace ${horas}h`;
}

export default function TarjetaPedido({ pedido, seleccionado, onClick }) {
  const pagado = pedido.pago?.estado === "pagado";

  return (
    <button
      onClick={onClick}
      className={`w-full text-left bg-white rounded-lg p-3 mb-2 border transition ${
        seleccionado ? "border-primary ring-1 ring-primary" : "border-gray-200 hover:border-gray-300"
      }`}
    >
      <div className="flex justify-between items-center mb-1">
        <span className="font-semibold text-sm text-dark">{pedido.codigo}</span>
        <span className="text-xs text-gray-400">{tiempoTranscurrido(pedido.createdAt)}</span>
      </div>
      <div className="flex items-center gap-1 text-xs text-gray-500 mb-2">
        {pedido.canal === "DELIVERY" ? "🛵 Delivery" : `🍽️ Mesa ${pedido.mesa?.numero ?? ""}`}
      </div>
      <div className="flex justify-between items-center">
        <span className="font-bold text-dark">S/. {Number(pedido.total).toFixed(2)}</span>
        <span
          className={`text-xs px-2 py-0.5 rounded-full ${
            pagado ? "bg-green-50 text-success" : "bg-yellow-50 text-warning"
          }`}
        >
          {pagado ? "Pagado" : "Pago pendiente"}
        </span>
      </div>
    </button>
  );
}