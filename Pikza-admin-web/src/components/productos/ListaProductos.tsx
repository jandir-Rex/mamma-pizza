// src/components/productos/ListaProductos.tsx
type Categoria = {
  id: number;
  nombre: string;
  parentId: number | null;
  areaPreparacion: "HORNO" | "BARRA" | null;
  padre?: { nombre: string } | null;
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

export default function ListaProductos({
  productos,
  onEditar,
  onDesactivar,
}: {
  productos: Producto[];
  onEditar: (p: Producto) => void;
  onDesactivar: (id: number) => void;
}) {
  return (
    <div className="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-xs dark:border-gray-800 dark:bg-gray-900">
      <table className="w-full table-fixed divide-y divide-gray-200 dark:divide-gray-800">
        <thead className="bg-gray-50 text-left text-xs font-bold uppercase tracking-wider text-gray-500 dark:bg-gray-800/50 dark:text-gray-400">
          <tr>
            <th className="w-4/12 px-5 py-4">Producto</th>
            <th className="w-2/12 px-4 py-4">Categoría</th>
            <th className="w-4/12 px-4 py-4">Tamaños y Precios</th>
            <th className="w-2/12 px-5 py-4 text-right">Acciones</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-100 text-sm dark:divide-gray-800">
          {productos.map((prod) => (
            <tr key={prod.id} className="hover:bg-gray-50/50 dark:hover:bg-white/[0.02]">
              {/* Producto (Blindado para no estirar el ancho) */}
              <td className="px-5 py-3.5">
                <div className="font-bold text-gray-900 dark:text-white truncate">
                  {prod.nombre}
                </div>
                <div
                  className="truncate text-xs text-gray-400 break-all"
                  title={prod.descripcion || ""}
                >
                  {prod.descripcion || "Sin descripción"}
                </div>
              </td>

              {/* Categoría */}
              <td className="px-4 py-3.5">
                <span className="inline-flex rounded-md bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-700 dark:bg-gray-800 dark:text-gray-300">
                  {prod.categoria?.padre
                    ? `${prod.categoria.padre.nombre} · ${prod.categoria.nombre}`
                    : prod.categoria?.nombre}
                </span>
              </td>

              {/* Tamaños y Precios */}
              <td className="px-4 py-3.5">
                <div className="flex flex-wrap gap-1 max-h-16 overflow-y-auto pr-1">
                  {prod.variantes.map((v, i) => (
                    <span
                      key={v.id || i}
                      className="rounded bg-brand-50 px-2 py-0.5 text-xs font-medium text-brand-700 dark:bg-brand-950/40 dark:text-brand-300"
                    >
                      {v.tamano}: <b>S/ {Number(v.precio).toFixed(2)}</b>
                    </span>
                  ))}
                </div>
              </td>

              {/* Acciones */}
              <td className="px-5 py-3.5 text-right">
                <div className="flex items-center justify-end gap-3">
                  <button
                    type="button"
                    onClick={() => onEditar(prod)}
                    className="text-xs font-bold text-brand-500 hover:underline"
                  >
                    Editar
                  </button>
                  <button
                    type="button"
                    onClick={() => onDesactivar(prod.id)}
                    className="text-xs font-semibold text-red-500 hover:underline"
                  >
                    Retirar
                  </button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}