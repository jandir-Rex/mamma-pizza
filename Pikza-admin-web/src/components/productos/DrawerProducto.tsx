// src/components/productos/DrawerProducto.tsx
import { useState } from "react";
import { apiRequest } from "@/services/api";

type Categoria = {
  id: number;
  nombre: string;
  parentId: number | null;
  areaPreparacion: "HORNO" | "BARRA" | null;
};
type Variante = { id?: number; tamano: string; precio: number };
type Producto = {
  id: number;
  nombre: string;
  descripcion?: string | null;
  categoriaId: number;
  categoria: Categoria;
  imagenUrl?: string | null;
  disponible: boolean;
  variantes: Variante[];
};

type VarianteForm = { id?: number; tamano: string; precio: string };

type Props = {
  abierto: boolean;
  productoEnEdicion: Producto | null;
  categorias: Categoria[];
  onCerrar: () => void;
  onGuardado: () => void;
};

// Subcomponente interno del formulario que se reinicia limpiamente con 'key'
function FormularioInterno({
  productoEnEdicion,
  categorias,
  onCerrar,
  onGuardado,
}: {
  productoEnEdicion: Producto | null;
  categorias: Categoria[];
  onCerrar: () => void;
  onGuardado: () => void;
}) {
  const categoriaActual = categorias.find((categoria) => categoria.id === productoEnEdicion?.categoriaId);
  const categoriasPrincipales = categorias.filter((categoria) => categoria.parentId === null);
  const [nombre, setNombre] = useState(productoEnEdicion?.nombre ?? "");
  const [descripcion, setDescripcion] = useState(productoEnEdicion?.descripcion ?? "");
  const [categoriaPadreId, setCategoriaPadreId] = useState<number | "">(
    categoriaActual?.parentId ?? categoriaActual?.id ?? categoriasPrincipales[0]?.id ?? ""
  );
  const [subcategoriaId, setSubcategoriaId] = useState<number | "">(
    categoriaActual?.parentId ? categoriaActual.id : ""
  );
  const [imagenUrl, setImagenUrl] = useState(productoEnEdicion?.imagenUrl ?? "");
  const [variantes, setVariantes] = useState<VarianteForm[]>(() => {
    if (productoEnEdicion?.variantes?.length) {
      return productoEnEdicion.variantes.map((v) => ({
        id: v.id,
        tamano: v.tamano,
        precio: Number(v.precio).toFixed(2),
      }));
    }
    return [{ tamano: "Personal", precio: "20.00" }];
  });
  const [guardando, setGuardando] = useState(false);

  function agregarVariante() {
    setVariantes((prev) => [...prev, { tamano: "", precio: "" }]);
  }

  function eliminarVariante(idx: number) {
    if (variantes.length <= 1) return;
    setVariantes((prev) => prev.filter((_, i) => i !== idx));
  }

  function actualizarVariante(idx: number, campo: "tamano" | "precio", val: string) {
    setVariantes((prev) => {
      const copia = [...prev];
      copia[idx][campo] = val;
      return copia;
    });
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!categoriaPadreId) return alert("Selecciona una categoría principal");

    setGuardando(true);
    try {
      const payloadVariantes = variantes.map((v) => ({
        ...(v.id ? { id: v.id } : {}),
        tamano: v.tamano.trim(),
        precio: Number(v.precio),
      }));

      const payload = {
        nombre: nombre.trim(),
        descripcion: descripcion.trim() || undefined,
        categoriaId: Number(subcategoriaId || categoriaPadreId),
        imagenUrl: imagenUrl.trim() || undefined,
        variantes: payloadVariantes,
      };

      if (productoEnEdicion) {
        await apiRequest(`/productos/${productoEnEdicion.id}`, {
          method: "PUT",
          body: JSON.stringify(payload),
        });
      } else {
        await apiRequest("/productos", {
          method: "POST",
          body: JSON.stringify(payload),
        });
      }

      onGuardado();
      onCerrar();
    } catch (err) {
      alert(err instanceof Error ? err.message : "Error al guardar el producto");
    } finally {
      setGuardando(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-1 flex-col justify-between overflow-y-auto">
      <div className="space-y-4.5 p-6">
        <div>
          <label className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
            Nombre del Producto *
          </label>
          <input
            type="text"
            required
            placeholder="Ej: Pizza Suprema, Gaseosa 1.5L..."
            value={nombre}
            onChange={(e) => setNombre(e.target.value)}
            className="mt-1.5 h-10 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
          />
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
              Categoría principal *
            </label>
            <select
              required
              value={categoriaPadreId}
              onChange={(e) => {
                setCategoriaPadreId(e.target.value ? Number(e.target.value) : "");
                setSubcategoriaId("");
              }}
              className="mt-1.5 h-10 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm font-semibold text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
            >
              <option value="">Selecciona categoría</option>
              {categoriasPrincipales.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.nombre}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
              Subcategoría (opcional)
            </label>
            <select
              value={subcategoriaId}
              disabled={!categorias.some((categoria) => categoria.parentId === Number(categoriaPadreId))}
              onChange={(e) => setSubcategoriaId(e.target.value ? Number(e.target.value) : "")}
              className="mt-1.5 h-10 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 outline-none focus:border-brand-500 disabled:cursor-not-allowed disabled:bg-gray-100 disabled:text-gray-400 dark:border-gray-700 dark:bg-gray-800 dark:text-white dark:disabled:bg-gray-900"
            >
              <option value="">Sin subcategoría</option>
              {categorias
                .filter((categoria) => categoria.parentId === Number(categoriaPadreId))
                .map((categoria) => (
                  <option key={categoria.id} value={categoria.id}>
                    {categoria.nombre}
                  </option>
                ))}
            </select>
          </div>

          <div className="col-span-2">
            <label className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
              URL Imagen (Opcional)
            </label>
            <input
              type="url"
              placeholder="https://..."
              value={imagenUrl}
              onChange={(e) => setImagenUrl(e.target.value)}
              className="mt-1.5 h-10 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
            />
          </div>
        </div>

        <div>
          <label className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
            Descripción
          </label>
          <textarea
            rows={2}
            placeholder="Ingredientes, detalles de preparación..."
            value={descripcion}
            onChange={(e) => setDescripcion(e.target.value)}
            className="mt-1.5 w-full rounded-lg border border-gray-300 bg-white p-3 text-sm text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
          />
        </div>

        {/* Repetidor de Variantes */}
        <div className="rounded-xl border border-gray-100 bg-gray-50/70 p-4 dark:border-gray-800 dark:bg-gray-800/40">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-gray-700 dark:text-gray-300">
              Tamaños y Precios
            </span>
            <button
              type="button"
              onClick={agregarVariante}
              className="text-xs font-bold text-brand-500 hover:underline"
            >
              + Agregar tamaño
            </button>
          </div>

          <div className="mt-3 space-y-2 max-h-48 overflow-y-auto pr-1">
            {variantes.map((v, i) => (
              <div key={i} className="flex items-center gap-2">
                <input
                  type="text"
                  required
                  placeholder="Tamaño (ej: Familiar)"
                  value={v.tamano}
                  onChange={(e) => actualizarVariante(i, "tamano", e.target.value)}
                  className="h-9 w-1/2 rounded-lg border border-gray-300 bg-white px-3 text-xs text-gray-800 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
                />
                <div className="relative w-1/2">
                  <span className="absolute left-2.5 top-2 text-xs font-medium text-gray-400">S/</span>
                  <input
                    type="number"
                    step="0.10"
                    min="0"
                    required
                    placeholder="0.00"
                    value={v.precio}
                    onChange={(e) => actualizarVariante(i, "precio", e.target.value)}
                    className="h-9 w-full rounded-lg border border-gray-300 bg-white pl-8 pr-3 text-xs text-gray-800 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
                  />
                </div>
                {variantes.length > 1 && (
                  <button
                    type="button"
                    onClick={() => eliminarVariante(i)}
                    className="flex size-7 items-center justify-center rounded text-gray-400 hover:text-red-500"
                  >
                    ✕
                  </button>
                )}
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="flex justify-end gap-3 border-t border-gray-100 bg-white px-6 py-4 dark:border-gray-800 dark:bg-gray-900">
        <button
          type="button"
          onClick={onCerrar}
          className="rounded-xl border border-gray-200 px-4 py-2.5 text-sm font-medium text-gray-600 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-300"
        >
          Cancelar
        </button>
        <button
          type="submit"
          disabled={guardando}
          className="rounded-xl bg-brand-500 px-6 py-2.5 text-sm font-bold text-white shadow-sm hover:bg-brand-600 disabled:opacity-50"
        >
          {guardando ? "Guardando..." : productoEnEdicion ? "Actualizar Cambios" : "Guardar Producto"}
        </button>
      </div>
    </form>
  );
}

export default function DrawerProducto({
  abierto,
  productoEnEdicion,
  categorias,
  onCerrar,
  onGuardado,
}: Props) {
  return (
    <div
      className={`fixed inset-0 z-50 transition-opacity duration-300 ease-in-out ${
        abierto ? "pointer-events-auto opacity-100" : "pointer-events-none opacity-0"
      }`}
    >
      <div onClick={onCerrar} className="fixed inset-0 bg-black/60 backdrop-blur-[2px] transition-opacity" />
      <div
        className={`absolute inset-y-0 right-0 flex w-full max-w-lg flex-col bg-white shadow-2xl transition-transform duration-300 ease-out dark:bg-gray-900 ${
          abierto ? "translate-x-0" : "translate-x-full"
        }`}
      >
        <div className="flex items-center justify-between border-b border-gray-100 px-6 py-4.5 dark:border-gray-800">
          <div>
            <h2 className="text-lg font-bold text-gray-900 dark:text-white">
              {productoEnEdicion ? "Editar Producto" : "Nuevo Producto"}
            </h2>
            <p className="text-xs text-gray-500">Configura nombres, foto y lista de tamaños con precio</p>
          </div>
          <button type="button" onClick={onCerrar} className="text-gray-400 hover:text-gray-600 dark:hover:text-white">
            ✕
          </button>
        </div>

        {/* Al usar key={...}, el formulario se inicializa sin necesidad de useEffect */}
        {abierto && (
          <FormularioInterno
            key={productoEnEdicion?.id ?? "nuevo"}
            productoEnEdicion={productoEnEdicion}
            categorias={categorias}
            onCerrar={onCerrar}
            onGuardado={onGuardado}
          />
        )}
      </div>
    </div>
  );
}