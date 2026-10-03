import { useEffect, useState } from "react";
import PanelDetallePedido from "@/components/PanelDetallePedido";
import FilaPedido from "@/components/FilaPedido";
import SelectorFechaPedido from "@/components/SelectorFechaPedido";
import { useAuth } from "@/context/AuthContext";
import { apiRequest } from "@/services/api";
import {
  fechaLocalHoy,
  obtenerVariantesMenu,
  rangoDiaLocal,
} from "@/services/pedidosCache";
import type { Pedido, VarianteInfo } from "@/types/pedido";

export default function HistorialPedidos() {
  const { usuario } = useAuth();
  const esRepartidor = usuario?.rol === "REPARTIDOR";
  const [fecha, setFecha] = useState(fechaLocalHoy);
  const [pedidos, setPedidos] = useState<Pedido[]>([]);
  const [variantesMap, setVariantesMap] = useState<Record<number, VarianteInfo>>({});
  const [seleccionado, setSeleccionado] = useState<Pedido | null>(null);
  const [busqueda, setBusqueda] = useState("");
  const [cargando, setCargando] = useState(true);
  const [actualizando, setActualizando] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    let activo = true;
    const rango = rangoDiaLocal(fecha);
    const parametros = new URLSearchParams(rango);

    Promise.all([
      apiRequest<Pedido[]>(`/pedidos/historial?${parametros.toString()}`),
      obtenerVariantesMenu(),
    ])
      .then(([lista, variantes]) => {
        if (!activo) return;
        setPedidos(lista);
        setVariantesMap(variantes);
        setError("");
      })
      .catch((err: unknown) => {
        if (activo) {
          setError(err instanceof Error ? err.message : "No se pudo cargar el historial");
        }
      })
      .finally(() => {
        if (activo) setCargando(false);
      });

    return () => {
      activo = false;
    };
  }, [fecha]);

  async function actualizarHistorial() {
    setActualizando(true);
    setError("");
    try {
      const rango = rangoDiaLocal(fecha);
      const parametros = new URLSearchParams(rango);
      const [lista, variantes] = await Promise.all([
        apiRequest<Pedido[]>(`/pedidos/historial?${parametros.toString()}`),
        obtenerVariantesMenu(true),
      ]);
      setPedidos(lista);
      setVariantesMap(variantes);
      setSeleccionado((actual) =>
        actual ? lista.find((pedido) => pedido.id === actual.id) ?? null : null,
      );
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudo actualizar el historial");
    } finally {
      setActualizando(false);
    }
  }

  const termino = busqueda.trim().toLocaleLowerCase("es");
  const pedidosFiltrados = pedidos.filter((pedido) =>
    pedido.codigo.toLocaleLowerCase("es").includes(termino) ||
    (pedido.clienteNombre ?? pedido.cliente?.nombre ?? "")
      .toLocaleLowerCase("es")
      .includes(termino),
  );

  return (
    <div className="space-y-5">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Historial de pedidos</h1>
          <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {esRepartidor
              ? "Busca pedidos por fecha entre los que tienes asignados y consulta su detalle."
              : usuario?.rol === "ADMIN"
                ? "Busca pedidos por fecha y consulta su detalle en modo lectura."
                : "Busca pedidos por fecha que registraste o continuaste y consulta su detalle."}
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <SelectorFechaPedido
            id="fecha-historial-pedidos"
            fecha={fecha}
            onSeleccionar={(nuevaFecha) => {
              setCargando(true);
              setError("");
              setSeleccionado(null);
              setFecha(nuevaFecha);
            }}
          />
          <button
            type="button"
            onClick={actualizarHistorial}
            disabled={actualizando}
            className="h-10 rounded-lg border border-gray-200 bg-white px-3.5 text-sm font-semibold text-gray-700 hover:bg-gray-50 disabled:opacity-50 dark:border-gray-800 dark:bg-gray-900 dark:text-gray-300"
          >
            {actualizando ? "Actualizando..." : "Actualizar"}
          </button>
          <input
            type="search"
            aria-label="Buscar pedido por código o cliente"
            placeholder="Buscar código o cliente..."
            value={busqueda}
            onChange={(event) => setBusqueda(event.target.value)}
            className="h-10 w-full rounded-lg border border-gray-200 bg-white px-3.5 text-sm text-gray-800 outline-none focus:border-brand-500 sm:w-56 dark:border-gray-800 dark:bg-gray-900 dark:text-white"
          />
        </div>
      </div>

      {error && (
        <div role="alert" className="rounded-xl bg-red-50 p-4 text-sm text-red-600 dark:bg-red-950/20 dark:text-red-400">
          {error}
        </div>
      )}

      <div className="overflow-hidden rounded-xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-900">
        <div className="flex items-center justify-between border-b border-gray-100 px-5 py-3 dark:border-gray-800">
          <h2 className="text-sm font-bold text-gray-800 dark:text-white">
            Pedidos del {new Date(`${fecha}T12:00:00`).toLocaleDateString("es-PE", {
              day: "numeric",
              month: "long",
              year: "numeric",
            })}
          </h2>
          <span className="text-xs text-gray-400">
            {pedidosFiltrados.length} resultado{pedidosFiltrados.length === 1 ? "" : "s"}
          </span>
        </div>

        <div className="flex min-h-80">
          <section className="min-w-0 flex-1" aria-label="Resultados del historial">
            {cargando ? (
              <p className="px-5 py-10 text-sm text-gray-500">Cargando historial...</p>
            ) : pedidosFiltrados.length === 0 ? (
              <p className="px-5 py-10 text-sm text-gray-500">
                No hay pedidos para esta fecha y búsqueda.
              </p>
            ) : (
              <div className="divide-y divide-gray-100 dark:divide-gray-800">
                {pedidosFiltrados.map((pedido) => (
                  <FilaPedido
                    key={pedido.id}
                    pedido={pedido}
                    seleccionado={seleccionado?.id === pedido.id}
                    onClick={() => setSeleccionado(pedido)}
                  />
                ))}
              </div>
            )}
          </section>

          {seleccionado && (
            <PanelDetallePedido
              pedido={seleccionado}
              variantesMap={variantesMap}
              onCerrar={() => setSeleccionado(null)}
              onActualizado={() => undefined}
              soloLectura
              puedeAgregarConsumos={false}
              puedeCobrar={false}
              puedeGestionarEstado={false}
            />
          )}
        </div>
      </div>
    </div>
  );
}
