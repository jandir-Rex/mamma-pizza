// src/components/productos/DrawerCategoria.tsx
import { useState } from "react";
import { apiRequest } from "@/services/api";
import { invalidarVariantesMenuCache } from "@/services/pedidosCache";

type AreaPreparacion = "HORNO" | "BARRA";
type Categoria = {
  id: number;
  nombre: string;
  parentId: number | null;
  areaPreparacion: AreaPreparacion | null;
};

type Props = {
  abierto: boolean;
  categorias: Categoria[];
  onCerrar: () => void;
  onCategoriaCreada: (cat: Categoria) => void;
  onAreaActualizada: (cat: Categoria) => void;
};

export default function DrawerCategoria({
  abierto,
  categorias,
  onCerrar,
  onCategoriaCreada,
  onAreaActualizada,
}: Props) {
  const [nombre, setNombre] = useState("");
  const [parentId, setParentId] = useState<number | "">("");
  const [areaPreparacion, setAreaPreparacion] = useState<AreaPreparacion | "HEREDAR">("HORNO");
  const [guardando, setGuardando] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!nombre.trim()) return;

    setGuardando(true);
    try {
      const cat = await apiRequest<Categoria>("/productos/categorias", {
        method: "POST",
        body: JSON.stringify({
          nombre: nombre.trim(),
          parentId: parentId === "" ? null : Number(parentId),
          areaPreparacion: areaPreparacion === "HEREDAR" ? null : areaPreparacion,
        }),
      });
      onCategoriaCreada(cat);
      setNombre("");
      setParentId("");
      setAreaPreparacion("HORNO");
      onCerrar();
    } catch (err) {
      alert(err instanceof Error ? err.message : "Error al crear categoría");
    } finally {
      setGuardando(false);
    }
  }

  async function cambiarAreaPreparacion(categoria: Categoria, valor: string) {
    const area = valor === "HEREDAR" ? null : valor as AreaPreparacion;
    setGuardando(true);
    try {
      const actualizada = await apiRequest<Categoria>(`/productos/categorias/${categoria.id}`, {
        method: "PATCH",
        body: JSON.stringify({ areaPreparacion: area }),
      });
      invalidarVariantesMenuCache();
      onAreaActualizada(actualizada);
    } catch (err) {
      alert(err instanceof Error ? err.message : "Error al actualizar el área de preparación");
    } finally {
      setGuardando(false);
    }
  }

  function selectorArea(categoria: Categoria) {
    const valor = categoria.areaPreparacion ?? (categoria.parentId ? "HEREDAR" : "HORNO");

    return (
      <select
        value={valor}
        disabled={guardando}
        onChange={(e) => cambiarAreaPreparacion(categoria, e.target.value)}
        aria-label={`Área de preparación de ${categoria.nombre}`}
        className="h-9 rounded-lg border border-gray-200 bg-white px-2 text-xs font-semibold text-gray-700 outline-none focus:border-brand-500 disabled:opacity-60 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-200"
      >
        {categoria.parentId !== null && <option value="HEREDAR">Heredar área</option>}
        <option value="HORNO">Horno / cocina</option>
        <option value="BARRA">Barra / bebidas</option>
      </select>
    );
  }

  return (
    <div
      className={`fixed inset-0 z-50 transition-opacity duration-300 ease-in-out ${
        abierto ? "pointer-events-auto opacity-100" : "pointer-events-none opacity-0"
      }`}
    >
      <div onClick={onCerrar} className="fixed inset-0 bg-black/60 backdrop-blur-[2px] transition-opacity" />
      <div
        className={`absolute inset-y-0 right-0 flex w-full max-w-sm flex-col bg-white shadow-2xl transition-transform duration-300 ease-out dark:bg-gray-900 ${
          abierto ? "translate-x-0" : "translate-x-full"
        }`}
      >
        <div className="flex items-center justify-between border-b border-gray-100 px-6 py-4.5 dark:border-gray-800">
          <h2 className="text-base font-bold text-gray-900 dark:text-white">
            Categorías y preparación
          </h2>
          <button type="button" onClick={onCerrar} className="text-gray-400 hover:text-gray-600 dark:hover:text-white">✕</button>
        </div>

        <form onSubmit={handleSubmit} className="flex min-h-0 flex-1 flex-col overflow-y-auto p-6">
          <div className="space-y-4">
            <h3 className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
              Crear categoría
            </h3>
            <div>
              <label className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                Categoría principal
              </label>
              <select
                value={parentId}
                onChange={(e) => {
                  setParentId(e.target.value ? Number(e.target.value) : "");
                  setAreaPreparacion(e.target.value ? "HEREDAR" : "HORNO");
                }}
                className="mt-1.5 h-10 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
              >
                <option value="">Crear como categoría principal</option>
                {categorias.filter((cat) => cat.parentId === null).map((cat) => (
                  <option key={cat.id} value={cat.id}>
                    Subcategoría de {cat.nombre}
                  </option>
                ))}
              </select>
              <p className="mt-1.5 text-xs text-gray-500 dark:text-gray-400">
                Las subcategorías se comparten en todo el catálogo y solo admiten un nivel.
              </p>
            </div>

            {parentId === "" ? (
              <div>
                <label className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                  Área de preparación
                </label>
                <select
                  value={areaPreparacion === "HEREDAR" ? "HORNO" : areaPreparacion}
                  onChange={(e) => setAreaPreparacion(e.target.value as AreaPreparacion)}
                  className="mt-1.5 h-10 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                >
                  <option value="HORNO">Horno / cocina</option>
                  <option value="BARRA">Barra / bebidas</option>
                </select>
              </div>
            ) : (
              <div>
                <label className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                  Área de preparación
                </label>
                <select
                  value={areaPreparacion}
                  onChange={(e) => setAreaPreparacion(e.target.value as AreaPreparacion | "HEREDAR")}
                  className="mt-1.5 h-10 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                >
                  <option value="HEREDAR">Heredar de categoría principal</option>
                  <option value="HORNO">Horno / cocina</option>
                  <option value="BARRA">Barra / bebidas</option>
                </select>
              </div>
            )}

            <div>
              <label className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                Nombre *
              </label>
              <input
                type="text"
                required
                placeholder="Ej: Pizzas Premium, Jugos..."
                value={nombre}
                onChange={(e) => setNombre(e.target.value)}
                className="mt-1.5 h-10 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
              />
            </div>

            <button
              type="submit"
              disabled={guardando || !nombre.trim()}
              className="w-full rounded-lg bg-brand-500 px-5 py-2.5 text-xs font-bold text-white hover:bg-brand-600 disabled:opacity-50"
            >
              {guardando ? "Guardando..." : parentId === "" ? "Crear categoría principal" : "Crear subcategoría"}
            </button>
          </div>

          <div className="mt-6 border-t border-gray-100 pt-5 dark:border-gray-800">
            <h3 className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
              Áreas por categoría
            </h3>
            <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
              Las subcategorías pueden heredar el área principal o usar otra.
            </p>
            <div className="mt-3 space-y-2">
              {categorias
                .filter((categoria) => categoria.parentId === null)
                .map((principal) => (
                  <div key={principal.id} className="rounded-xl border border-gray-200 p-3 dark:border-gray-800">
                    <div className="flex items-center justify-between gap-2">
                      <span className="min-w-0 truncate text-sm font-bold text-gray-800 dark:text-white">
                        {principal.nombre}
                      </span>
                      {selectorArea(principal)}
                    </div>
                    {categorias
                      .filter((categoria) => categoria.parentId === principal.id)
                      .map((subcategoria) => (
                        <div
                          key={subcategoria.id}
                          className="mt-2 flex items-center justify-between gap-2 border-t border-gray-100 pt-2 pl-3 dark:border-gray-800"
                        >
                          <span className="min-w-0 truncate text-xs text-gray-600 dark:text-gray-300">
                            {subcategoria.nombre}
                          </span>
                          {selectorArea(subcategoria)}
                        </div>
                      ))}
                  </div>
                ))}
            </div>
          </div>

          <div className="mt-6 flex justify-end border-t border-gray-100 pt-4 dark:border-gray-800">
            <button
              type="button"
              onClick={onCerrar}
              className="rounded-lg border px-4 py-2 text-xs font-semibold text-gray-600 dark:border-gray-700 dark:text-gray-300"
            >
              Cerrar
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}