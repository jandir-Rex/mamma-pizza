import { useEffect, useState } from "react";
import api from "../services/api";
import { obtenerSocket } from "../services/socket";
import { useAuth } from "../context/AuthContext";
import TarjetaPedido from "../components/TarjetaPedido";
import PanelDetallePedido from "../components/PanelDetallePedido";

const COLUMNAS = [
  { estado: "PENDIENTE_PAGO", titulo: "Pendiente de pago" },
  { estado: "CONFIRMADO", titulo: "Confirmado" },
  { estado: "EN_PREPARACION", titulo: "En preparación" },
  { estado: "EN_CAMINO", titulo: "En camino" },
  { estado: "ENTREGADO", titulo: "Entregado" },
];

export default function Pedidos() {
  const { usuario, logout } = useAuth();
  const [pedidos, setPedidos] = useState([]);
  const [variantesMap, setVariantesMap] = useState({});
  const [seleccionado, setSeleccionado] = useState(null);
  const [busqueda, setBusqueda] = useState("");
  const [conectado, setConectado] = useState(false);

  useEffect(() => {
    async function cargarDatos() {
      const [resPedidos, resMenu] = await Promise.all([
        api.get("/pedidos"),
        api.get("/productos/menu"),
      ]);
      setPedidos(resPedidos.data);

      const mapa = {};
      resMenu.data.forEach((producto) => {
        producto.variantes.forEach((v) => {
          mapa[v.id] = { nombre: producto.nombre, tamano: v.tamano };
        });
      });
      setVariantesMap(mapa);
    }
    cargarDatos();
  }, []);

  useEffect(() => {
    const socket = obtenerSocket();
    if (!socket) return;

    setConectado(socket.connected);
    socket.on("connect", () => setConectado(true));
    socket.on("disconnect", () => setConectado(false));

    socket.on("pedido:nuevo", (pedido) => {
      setPedidos((prev) => [pedido, ...prev]);
    });

    socket.on("pedido:actualizado", (pedido) => {
      setPedidos((prev) => prev.map((p) => (p.id === pedido.id ? { ...p, ...pedido } : p)));
      setSeleccionado((prev) => (prev && prev.id === pedido.id ? { ...prev, ...pedido } : prev));
    });

    return () => {
      socket.off("connect");
      socket.off("disconnect");
      socket.off("pedido:nuevo");
      socket.off("pedido:actualizado");
    };
  }, []);

  function actualizarPedidoLocal(pedidoActualizado) {
    setPedidos((prev) =>
      prev.map((p) => (p.id === pedidoActualizado.id ? { ...p, ...pedidoActualizado } : p))
    );
    setSeleccionado((prev) => (prev ? { ...prev, ...pedidoActualizado } : prev));
  }

  const pedidosFiltrados = pedidos.filter((p) =>
    p.codigo.toLowerCase().includes(busqueda.toLowerCase())
  );
  const activos = pedidos.filter((p) => !["ENTREGADO", "CANCELADO"].includes(p.estado)).length;

  return (
    <div className="h-screen flex flex-col">
      <header className="flex items-center justify-between bg-white border-b px-4 py-3">
        <div>
          <h1 className="font-bold text-primary">🍕 Mamma Pizza — Panel de Administración</h1>
          <span className="text-xs text-gray-400">{usuario?.nombre}</span>
        </div>
        <div className="flex items-center gap-4">
          <input
            type="text"
            placeholder="Buscar por código..."
            value={busqueda}
            onChange={(e) => setBusqueda(e.target.value)}
            className="border rounded-md px-3 py-1.5 text-sm outline-none focus:border-primary"
          />
          <span className="text-sm text-gray-500">{activos} activos</span>
          <span className="flex items-center gap-1 text-xs">
            <span className={`w-2 h-2 rounded-full ${conectado ? "bg-success" : "bg-danger"}`} />
            {conectado ? "En vivo" : "Sin conexión"}
          </span>
          <button onClick={logout} className="text-sm text-danger underline">
            Salir
          </button>
        </div>
      </header>

      <div className="flex flex-1 overflow-hidden">
        <div className="flex-1 flex gap-3 p-4 overflow-x-auto">
          {COLUMNAS.map((col) => {
            const items = pedidosFiltrados.filter((p) => p.estado === col.estado);
            return (
              <div key={col.estado} className="bg-gray-50 rounded-lg p-3 w-64 flex-shrink-0">
                <h2 className="text-sm font-semibold text-dark mb-3">
                  {col.titulo} <span className="text-gray-400">({items.length})</span>
                </h2>
                {items.map((pedido) => (
                  <TarjetaPedido
                    key={pedido.id}
                    pedido={pedido}
                    seleccionado={seleccionado?.id === pedido.id}
                    onClick={() => setSeleccionado(pedido)}
                  />
                ))}
              </div>
            );
          })}
        </div>

        <PanelDetallePedido
          pedido={seleccionado}
          variantesMap={variantesMap}
          onCerrar={() => setSeleccionado(null)}
          onActualizado={actualizarPedidoLocal}
        />
      </div>
    </div>
  );
}