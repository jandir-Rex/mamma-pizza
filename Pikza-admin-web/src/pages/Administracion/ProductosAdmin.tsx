// src/pages/Administracion/ProductosAdmin.tsx
import { useEffect, useState } from "react";
import { apiRequest } from "@/services/api";
import DrawerProducto from "@/components/productos/DrawerProducto";
import DrawerCategoria from "@/components/productos/DrawerCategoria";
import GridProductos from "@/components/productos/GridProductos";
import ListaProductos from "@/components/productos/ListaProductos";

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

export default function ProductosAdmin() {
  const [productos, setProductos] = useState<Producto[]>([]);
  const [categorias, setCategorias] = useState<Categoria[]>([]);
  const [categoriaFiltro, setCategoriaFiltro] = useState<number | "TODAS">("TODAS");
  const [busqueda, setBusqueda] = useState("");
  const [modoVista, setModoVista] = useState<"GRID" | "LISTA">("GRID");
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState("");

  const [drawerProductoAbierto, setDrawerProductoAbierto] = useState(false);
  const [drawerCategoriaAbierto, setDrawerCategoriaAbierto] = useState(false);
  const [productoEnEdicion, setProductoEnEdicion] = useState<Producto | null>(null);

  useEffect(() => {
    cargarDatos();
  }, []);

  async function cargarDatos() {
    setCargando(true);
    setError("");
    try {
      const [listaMenu, listaCat] = await Promise.all([
        apiRequest<Producto[]>("/productos/menu"),
        apiRequest<Categoria[]>("/productos/categorias"),
      ]);
      setProductos(listaMenu);
      setCategorias(listaCat);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error al cargar carta");
    } finally {
      setCargando(false);
    }
  }

  function abrirCrear() {
    setProductoEnEdicion(null);
    setDrawerProductoAbierto(true);
  }

  function abrirEditar(prod: Producto) {
    setProductoEnEdicion(prod);
    setDrawerProductoAbierto(true);
  }

  async function handleDesactivar(id: number) {
    if (!confirm("¿Deseas retirar este producto de la carta?")) return;
    try {
      await apiRequest(`/productos/${id}`, { method: "DELETE" });
      setProductos((prev) => prev.filter((p) => p.id !== id));
    } catch (err) {
      alert(err instanceof Error ? err.message : "No se pudo desactivar");
    }
  }

  const categoriaActiva = categorias.find((categoria) => categoria.id === categoriaFiltro);
  const categoriaPrincipalActiva = categoriaActiva?.parentId
    ? categorias.find((categoria) => categoria.id === categoriaActiva.parentId)
    : categoriaActiva;
  const subcategoriasActivas = categorias.filter(
    (categoria) => categoria.parentId === categoriaPrincipalActiva?.id
  );

  const productosFiltrados = productos.filter((p) => {
    const coincideCat =
      categoriaFiltro === "TODAS" ||
      (categoriaActiva?.parentId
        ? p.categoriaId === categoriaActiva.id
        : p.categoriaId === categoriaFiltro ||
          subcategoriasActivas.some((subcategoria) => subcategoria.id === p.categoriaId));
    const coincideNombre = p.nombre.toLowerCase().includes(busqueda.toLowerCase());
    return coincideCat && coincideNombre;
  });

  return (
    <div className="space-y-6">
      {/* Cabecera */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="text-sm text-gray-500 dark:text-gray-400">Catálogo</p>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Carta & Productos</h1>
        </div>

        <div className="flex items-center gap-3">
          <div className="flex rounded-xl border border-gray-200 bg-white p-1 dark:border-gray-800 dark:bg-gray-800">
            <button
              type="button"
              onClick={() => setModoVista("GRID")}
              className={`rounded-lg px-3 py-1.5 text-xs font-bold transition ${
                modoVista === "GRID"
                  ? "bg-brand-500 text-white shadow-xs"
                  : "text-gray-600 hover:text-gray-900 dark:text-gray-300"
              }`}
            >
              Tarjetas
            </button>
            <button
              type="button"
              onClick={() => setModoVista("LISTA")}
              className={`rounded-lg px-3 py-1.5 text-xs font-bold transition ${
                modoVista === "LISTA"
                  ? "bg-brand-500 text-white shadow-xs"
                  : "text-gray-600 hover:text-gray-900 dark:text-gray-300"
              }`}
            >
              Lista
            </button>
          </div>

          <button
            type="button"
            onClick={abrirCrear}
            className="rounded-xl bg-brand-500 px-4 py-2 text-sm font-bold text-white shadow-sm hover:bg-brand-600"
          >
            + Nuevo Producto
          </button>
        </div>
      </div>

      {error && <div className="rounded-xl bg-red-50 p-4 text-sm text-red-600">{error}</div>}

      {/* Filtros de Categoría y Buscador */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div className="flex gap-2 overflow-x-auto pb-1">
          <button
            type="button"
            onClick={() => setCategoriaFiltro("TODAS")}
            className={`whitespace-nowrap rounded-lg px-3.5 py-1.5 text-xs font-bold transition ${
              categoriaFiltro === "TODAS"
                ? "bg-brand-500 text-white shadow-xs"
                : "bg-white text-gray-600 hover:bg-gray-50 dark:bg-gray-800 dark:text-gray-300"
            }`}
          >
            Todas ({productos.length})
          </button>
          {categorias.filter((cat) => cat.parentId === null).map((cat) => (
            <button
              key={cat.id}
              type="button"
              onClick={() => setCategoriaFiltro(cat.id)}
              className={`whitespace-nowrap rounded-lg px-3.5 py-1.5 text-xs font-bold transition ${
                categoriaActiva?.id === cat.id || categoriaActiva?.parentId === cat.id
                  ? "bg-brand-500 text-white shadow-xs"
                  : "bg-white text-gray-600 hover:bg-gray-50 dark:bg-gray-800 dark:text-gray-300"
              }`}
            >
              {cat.nombre}
            </button>
          ))}
          <button
            type="button"
            onClick={() => setDrawerCategoriaAbierto(true)}
            className="whitespace-nowrap rounded-lg border border-dashed border-gray-300 px-3 py-1.5 text-xs font-semibold text-gray-500 hover:bg-gray-50 dark:border-gray-700"
          >
            + Categoría
          </button>
        </div>

        <input
          type="search"
          placeholder="Buscar pizza, bebida..."
          value={busqueda}
          onChange={(e) => setBusqueda(e.target.value)}
          className="h-10 w-full rounded-xl border border-gray-300 bg-white px-3.5 text-sm text-gray-800 outline-none focus:border-brand-500 md:w-64 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
        />
      </div>

      {categoriaPrincipalActiva && subcategoriasActivas.length > 0 && (
        <div className="flex gap-2 overflow-x-auto pb-1">
          <button
            type="button"
            onClick={() => setCategoriaFiltro(categoriaPrincipalActiva.id)}
            className={`whitespace-nowrap rounded-lg px-3 py-1.5 text-xs font-semibold transition ${
              categoriaFiltro === categoriaPrincipalActiva.id
                ? "bg-brand-100 text-brand-700 dark:bg-brand-950/40 dark:text-brand-300"
                : "bg-gray-100 text-gray-600 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-300"
            }`}
          >
            Todas las {categoriaPrincipalActiva.nombre}
          </button>
          {subcategoriasActivas.map((subcategoria) => (
            <button
              key={subcategoria.id}
              type="button"
              onClick={() => setCategoriaFiltro(subcategoria.id)}
              className={`whitespace-nowrap rounded-lg px-3 py-1.5 text-xs font-semibold transition ${
                categoriaFiltro === subcategoria.id
                  ? "bg-brand-100 text-brand-700 dark:bg-brand-950/40 dark:text-brand-300"
                  : "bg-gray-100 text-gray-600 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-300"
              }`}
            >
              {subcategoria.nombre}
            </button>
          ))}
        </div>
      )}

      {/* Contenido Modular */}
      {cargando ? (
        <p className="py-12 text-center text-sm text-gray-400">Cargando carta...</p>
      ) : productosFiltrados.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-gray-200 py-12 text-center dark:border-gray-800">
          <p className="text-sm text-gray-500">No hay productos en esta vista.</p>
        </div>
      ) : modoVista === "GRID" ? (
        <GridProductos
          productos={productosFiltrados}
          onEditar={abrirEditar}
          onDesactivar={handleDesactivar}
        />
      ) : (
        <ListaProductos
          productos={productosFiltrados}
          onEditar={abrirEditar}
          onDesactivar={handleDesactivar}
        />
      )}

      {/* Drawers Subcomponentes */}
      <DrawerProducto
        abierto={drawerProductoAbierto}
        productoEnEdicion={productoEnEdicion}
        categorias={categorias}
        onCerrar={() => setDrawerProductoAbierto(false)}
        onGuardado={cargarDatos}
      />

      <DrawerCategoria
        abierto={drawerCategoriaAbierto}
        categorias={categorias}
        onCerrar={() => setDrawerCategoriaAbierto(false)}
        onCategoriaCreada={(cat) => {
          setCategorias((prev) => [...prev, cat]);
          setCategoriaFiltro(cat.id);
        }}
        onAreaActualizada={(categoriaActualizada) => {
          setCategorias((prev) =>
            prev.map((categoria) =>
              categoria.id === categoriaActualizada.id ? categoriaActualizada : categoria
            )
          );
        }}
      />
    </div>
  );
}