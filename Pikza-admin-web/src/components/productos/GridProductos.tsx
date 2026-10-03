// src/components/productos/GridProductos.tsx
import { useState } from "react";

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

function PizzaIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" {...props}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M12 2a10 10 0 1 0 10 10" />
      <path strokeLinecap="round" strokeLinejoin="round" d="m21.17 8-7.17 4V2" />
      <circle cx="9" cy="9" r="1" fill="currentColor" />
      <circle cx="14" cy="14" r="1" fill="currentColor" />
      <circle cx="8" cy="15" r="1" fill="currentColor" />
    </svg>
  );
}

function TarjetaProducto({
  prod,
  onEditar,
  onDesactivar,
}: {
  prod: Producto;
  onEditar: (p: Producto) => void;
  onDesactivar: (id: number) => void;
}) {
  const [imgError, setImgError] = useState(false);

  return (
    <div className="flex h-[380px] flex-col overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-xs transition hover:shadow-md dark:border-gray-800 dark:bg-gray-900">
      {/* Imagen con fallback blindado */}
      <div className="relative h-40 w-full shrink-0 overflow-hidden bg-gray-100 dark:bg-gray-800">
        {prod.imagenUrl && !imgError ? (
          <img
            src={prod.imagenUrl}
            alt={prod.nombre}
            onError={() => setImgError(true)}
            className="h-full w-full object-cover"
          />
        ) : (
          <div className="flex h-full w-full items-center justify-center text-gray-300 dark:text-gray-700">
            <PizzaIcon className="size-12" />
          </div>
        )}
        <span className="absolute left-3 top-3 rounded-md bg-white/90 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-gray-800 backdrop-blur-xs dark:bg-gray-900/90 dark:text-white">
          {prod.categoria?.padre
            ? `${prod.categoria.padre.nombre} · ${prod.categoria.nombre}`
            : prod.categoria?.nombre}
        </span>
      </div>

      {/* Contenido con límites estrictos */}
      <div className="flex flex-1 flex-col justify-between p-4 min-h-0">
        <div>
          <h3 className="truncate text-sm font-bold text-gray-900 dark:text-white" title={prod.nombre}>
            {prod.nombre}
          </h3>
          <p
            className="mt-1 line-clamp-2 text-xs text-gray-500 break-all dark:text-gray-400"
            title={prod.descripcion || ""}
          >
            {prod.descripcion || "Sin descripción"}
          </p>
        </div>

        {/* Variantes con caja scrolleable interna (nunca estira la tarjeta) */}
        <div className="my-2 max-h-24 overflow-y-auto space-y-1 pr-1 [&::-webkit-scrollbar]:w-1 [&::-webkit-scrollbar-thumb]:bg-gray-300 dark:[&::-webkit-scrollbar-thumb]:bg-gray-700">
          {prod.variantes.map((v, i) => (
            <div key={v.id || i} className="flex items-center justify-between text-xs">
              <span className="truncate max-w-[120px] text-gray-600 dark:text-gray-400">{v.tamano}</span>
              <span className="font-bold text-gray-900 dark:text-white">S/ {Number(v.precio).toFixed(2)}</span>
            </div>
          ))}
        </div>

        {/* Acciones fijadas abajo */}
        <div className="flex items-center justify-between border-t border-gray-100 pt-2.5 dark:border-gray-800">
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
      </div>
    </div>
  );
}

export default function GridProductos({
  productos,
  onEditar,
  onDesactivar,
}: {
  productos: Producto[];
  onEditar: (p: Producto) => void;
  onDesactivar: (id: number) => void;
}) {
  return (
    <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
      {productos.map((prod) => (
        <TarjetaProducto
          key={prod.id}
          prod={prod}
          onEditar={onEditar}
          onDesactivar={onDesactivar}
        />
      ))}
    </div>
  );
}