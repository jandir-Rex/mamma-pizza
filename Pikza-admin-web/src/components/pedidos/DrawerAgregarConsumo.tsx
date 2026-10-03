// src/components/pedidos/DrawerAgregarConsumo.tsx
import { useEffect, useState } from "react";
import { apiRequest } from "@/services/api";
import type { Pedido } from "@/types/pedido";

type MenuProducto = {
  id: number;
  nombre: string;
  variantes: { id: number; tamano: string; precio: number }[];
};

type ItemConsumo = {
  productoVarianteId: number;
  nombre: string;
  tamano: string;
  precio: number;
  cantidad: number;
};

type Props = {
  abierto: boolean;
  pedido: Pedido;
  onCerrar: () => void;
  onActualizado: (pedido: Pedido) => void;
};

export default function DrawerAgregarConsumo({ abierto, pedido, onCerrar, onActualizado }: Props) {
  const [catalogoMenu, setCatalogoMenu] = useState<MenuProducto[]>([]);
  const [itemsParaAgregar, setItemsParaAgregar] = useState<ItemConsumo[]>([]);
  const [guardando, setGuardando] = useState(false);

  useEffect(() => {
    if (abierto && catalogoMenu.length === 0) {
      apiRequest<MenuProducto[]>("/productos/menu")
        .then((res) => setCatalogoMenu(res))
        .catch((err) => console.error("Error al cargar productos:", err));
    }
  }, [abierto, catalogoMenu.length]);

  function sumarItem(prod: MenuProducto, v: { id: number; tamano: string; precio: number }) {
    setItemsParaAgregar((prev) => {
      const idx = prev.findIndex((i) => i.productoVarianteId === v.id);
      if (idx >= 0) {
        const copia = [...prev];
        copia[idx].cantidad += 1;
        return copia;
      }
      return [
        ...prev,
        {
          productoVarianteId: v.id,
          nombre: prod.nombre,
          tamano: v.tamano,
          precio: Number(v.precio),
          cantidad: 1,
        },
      ];
    });
  }

  async function enviarNuevosConsumos() {
    if (itemsParaAgregar.length === 0) return;
    setGuardando(true);
    try {
      const payload = {
        items: itemsParaAgregar.map((i) => ({
          productoVarianteId: i.productoVarianteId,
          cantidad: i.cantidad,
        })),
      };

      const pedidoActualizado = await apiRequest<Pedido>(`/pedidos/${pedido.id}/items`, {
        method: "POST",
        body: JSON.stringify(payload),
      });

      onActualizado(pedidoActualizado);
      setItemsParaAgregar([]);
      onCerrar();
    } catch (err) {
      alert(err instanceof Error ? err.message : "Error al agregar productos al pedido");
    } finally {
      setGuardando(false);
    }
  }

  return (
    <div
      className={`fixed inset-0 z-50 transition-opacity duration-300 ease-in-out ${
        abierto ? "pointer-events-auto opacity-100" : "pointer-events-none opacity-0"
      }`}
    >
      <div
        onClick={() => {
          setItemsParaAgregar([]);
          onCerrar();
        }}
        className="fixed inset-0 bg-black/60 backdrop-blur-[2px] transition-opacity"
      />

      <div
        className={`absolute inset-y-0 right-0 flex w-full max-w-md flex-col bg-white shadow-2xl transition-transform duration-300 ease-out dark:bg-gray-900 ${
          abierto ? "translate-x-0" : "translate-x-full"
        }`}
      >
        <div className="flex items-center justify-between border-b border-gray-100 p-5 dark:border-gray-800">
          <div>
            <h3 className="text-base font-bold text-gray-900 dark:text-white">
              Agregar a Comanda ({pedido.codigo})
            </h3>
            <p className="text-xs text-gray-500">Mesa #{pedido.mesa?.numero ?? "Para Llevar"}</p>
          </div>
          <button
            type="button"
            onClick={() => {
              setItemsParaAgregar([]);
              onCerrar();
            }}
            className="text-gray-400 hover:text-gray-600 dark:hover:text-white"
          >
            ✕
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-5 space-y-3">
          <p className="text-xs font-bold uppercase tracking-wider text-gray-400">Selecciona producto y tamaño:</p>
          {catalogoMenu.map((prod) => (
            <div
              key={prod.id}
              className="rounded-xl border border-gray-100 p-3 bg-gray-50/50 dark:border-gray-800 dark:bg-gray-800/40"
            >
              <div className="text-sm font-bold text-gray-800 dark:text-white">{prod.nombre}</div>
              <div className="mt-2 flex flex-wrap gap-1.5">
                {prod.variantes.map((v) => (
                  <button
                    key={v.id}
                    type="button"
                    onClick={() => sumarItem(prod, v)}
                    className="rounded-lg border border-brand-200 bg-white px-2.5 py-1 text-xs font-semibold text-brand-600 hover:bg-brand-500 hover:text-white dark:border-gray-700 dark:bg-gray-800 dark:text-brand-300 dark:hover:bg-brand-500 dark:hover:text-white"
                  >
                    {v.tamano} S/ {Number(v.precio).toFixed(2)} +
                  </button>
                ))}
              </div>
            </div>
          ))}
        </div>

        {itemsParaAgregar.length > 0 && (
          <div className="border-t border-gray-100 bg-gray-50/80 p-4 dark:border-gray-800 dark:bg-gray-800/60">
            <p className="text-xs font-bold text-gray-700 dark:text-gray-300 mb-2">Por agregar ahora:</p>
            <div className="space-y-1">
              {itemsParaAgregar.map((it, i) => (
                <div key={i} className="flex justify-between text-xs text-gray-600 dark:text-gray-300">
                  <span>
                    {it.cantidad}x {it.nombre} ({it.tamano})
                  </span>
                  <span className="font-bold">S/ {(it.precio * it.cantidad).toFixed(2)}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        <div className="flex justify-end gap-2 border-t border-gray-100 p-4 dark:border-gray-800">
          <button
            type="button"
            onClick={() => {
              setItemsParaAgregar([]);
              onCerrar();
            }}
            className="rounded-lg border px-4 py-2 text-xs font-semibold text-gray-600 dark:border-gray-700 dark:text-gray-300"
          >
            Cancelar
          </button>
          <button
            type="button"
            disabled={guardando || itemsParaAgregar.length === 0}
            onClick={enviarNuevosConsumos}
            className="rounded-lg bg-brand-500 px-5 py-2 text-xs font-bold text-white hover:bg-brand-600 disabled:opacity-50"
          >
            {guardando ? "Enviando..." : "Confirmar y Sumar a la Cuenta"}
          </button>
        </div>
      </div>
    </div>
  );
}