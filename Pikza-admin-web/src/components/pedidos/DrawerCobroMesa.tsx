// src/components/pedidos/DrawerCobroMesa.tsx
import { useState } from "react";
import { formatoPrecio, type Pedido } from "@/types/pedido";

type Props = {
  abierto: boolean;
  pedido: Pedido;
  cargando: boolean;
  onCerrar: () => void;
  onConfirmar: (metodo: "EFECTIVO" | "YAPE" | "TARJETA") => Promise<void>;
};

export default function DrawerCobroMesa({
  abierto,
  pedido,
  cargando,
  onCerrar,
  onConfirmar,
}: Props) {
  const [metodo, setMetodo] = useState<"EFECTIVO" | "YAPE" | "TARJETA">("EFECTIVO");

  return (
    <div
      className={`fixed inset-0 z-50 transition-opacity duration-300 ease-in-out ${
        abierto ? "pointer-events-auto opacity-100" : "pointer-events-none opacity-0"
      }`}
    >
      <div onClick={onCerrar} className="fixed inset-0 bg-black/60 backdrop-blur-[2px] transition-opacity" />

      <div
        className={`absolute inset-y-0 right-0 flex w-full max-w-sm flex-col justify-between bg-white p-6 shadow-2xl transition-transform duration-300 ease-out dark:bg-gray-900 ${
          abierto ? "translate-x-0" : "translate-x-full"
        }`}
      >
        <div>
          <div className="flex items-center justify-between border-b border-gray-100 pb-4 dark:border-gray-800">
            <h3 className="text-base font-bold text-gray-900 dark:text-white">Liquidación de Cuenta</h3>
            <button type="button" onClick={onCerrar} className="text-gray-400 hover:text-gray-600 dark:hover:text-white">
              ✕
            </button>
          </div>

          <div className="mt-6 text-center">
            <span className="text-xs font-bold uppercase tracking-wider text-gray-400">Total a Cobrar</span>
            <div className="mt-1 text-3xl font-black text-brand-500">{formatoPrecio(pedido.total)}</div>
            <p className="mt-1 text-xs text-gray-500">
              {pedido.canal === "DELIVERY"
                ? "Pedido de delivery"
                : pedido.mesa?.numero
                  ? `Mesa #${pedido.mesa.numero}`
                  : "Pedido para llevar"}
            </p>
          </div>

          <div className="mt-6">
            <label className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
              ¿Cómo pagó el cliente?
            </label>
            <div className="mt-2 grid grid-cols-3 gap-2">
              {(["EFECTIVO", "YAPE", "TARJETA"] as const).map((m) => (
                <button
                  key={m}
                  type="button"
                  onClick={() => setMetodo(m)}
                  className={`rounded-xl py-2.5 text-xs font-bold transition ${
                    metodo === m
                      ? "bg-brand-500 text-white shadow-xs"
                      : "border border-gray-200 bg-white text-gray-700 hover:bg-gray-100 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300"
                  }`}
                >
                  {m}
                </button>
              ))}
            </div>
          </div>
        </div>

        <div className="space-y-2 border-t border-gray-100 pt-4 dark:border-gray-800">
          <button
            type="button"
            disabled={cargando}
            onClick={() => onConfirmar(metodo)}
            className="w-full rounded-xl bg-emerald-600 py-3.5 text-sm font-bold text-white shadow-md hover:bg-emerald-700 disabled:opacity-50"
          >
            {cargando
              ? "Procesando..."
              : pedido.canal === "DELIVERY"
                ? "Confirmar cobro"
                : "Confirmar cobro y finalizar cuenta"}
          </button>
          <button
            type="button"
            onClick={onCerrar}
            className="w-full rounded-xl border border-gray-200 py-2.5 text-xs font-semibold text-gray-600 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-400"
          >
            Cancelar
          </button>
        </div>
      </div>
    </div>
  );
}