// src/components/DrawerCrearPedido.tsx
import { useEffect, useState } from "react";
import { apiRequest } from "@/services/api";

type CanalCreacion = "SALON" | "PARA_LLEVAR";

// --- ICONOS PROFESIONALES ---
function SearchIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.7" {...props}>
      <path strokeLinecap="round" strokeLinejoin="round" d="m19 19-4-4m0-7A7 7 0 1 1 1 8a7 7 0 0 1 14 0Z" />
    </svg>
  );
}

function CloseIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.8" {...props}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M6 6l8 8m0-8-8 8" />
    </svg>
  );
}

function TrashIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6" {...props}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M3 5h14M8 5V3h4v2m-7 0 1 12h8l1-12M8 9v6m4-6v6" />
    </svg>
  );
}

function UserIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6" {...props}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M10 10a4 4 0 1 0 0-8 4 4 0 0 0 0 8Zm-7 8a7 7 0 0 1 14 0H3Z" />
    </svg>
  );
}

function TableIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6" {...props}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M2 6h16M5 6v10M15 6v10M2 10h16" />
    </svg>
  );
}

function TakeoutIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6" {...props}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M4 6h12l-1 11H5L4 6Zm3 0V4a3 3 0 0 1 6 0v2" />
    </svg>
  );
}

function GridViewIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.7" {...props}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M3 3h5v5H3V3Zm9 0h5v5h-5V3Zm-9 9h5v5H3v-5Zm9 0h5v5h-5v-5Z" />
    </svg>
  );
}

function ListViewIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.7" {...props}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M3 5h14M3 10h14M3 15h14" />
    </svg>
  );
}

type Categoria = {
  id: number;
  nombre: string;
  parentId: number | null;
  areaPreparacion: "HORNO" | "BARRA" | null;
};
type Variante = { id: number; tamano: string; precio: number };
type Producto = {
  id: number;
  nombre: string;
  descripcion?: string | null;
  categoriaId: number;
  imagenUrl?: string | null;
  variantes: Variante[];
};

type Mesa = {
  id: number;
  numero: number;
  capacidad?: number | null;
  ocupada?: boolean;
  pedidoActivo?: {
    id: number;
    codigo: string;
    total: number | string;
    estado: string;
  } | null;
};

type ItemTicket = {
  productoVarianteId: number;
  productoNombre: string;
  tamano: string;
  precioUnitario: number;
  cantidad: number;
  notas: string;
};

type Props = {
  abierto: boolean;
  onCerrar: () => void;
  onPedidoCreado: () => void;
  canalesDisponibles: CanalCreacion[];
};

function obtenerMesasPorDefecto(): Mesa[] {
  return Array.from({ length: 10 }, (_, i) => ({
    id: i + 1,
    numero: i + 1,
    ocupada: false,
    pedidoActivo: null,
  }));
}

export default function DrawerCrearPedido({
  abierto,
  onCerrar,
  onPedidoCreado,
  canalesDisponibles,
}: Props) {
  const [productos, setProductos] = useState<Producto[]>([]);
  const [categorias, setCategorias] = useState<Categoria[]>([]);
  const [mesas, setMesas] = useState<Mesa[]>([]);
  const [categoriaActiva, setCategoriaActiva] = useState<number | "TODAS">("TODAS");
  const [busqueda, setBusqueda] = useState("");
  const [modoVista, setModoVista] = useState<"GRID" | "LISTA">("GRID");
  const [cargando, setCargando] = useState(false);
  const [vistaMovil, setVistaMovil] = useState<"CATALOGO" | "PEDIDO">("CATALOGO");

  // Estados del Ticket
  const [tipoAtencion, setTipoAtencion] = useState<"SALON" | "PARA_LLEVAR">("SALON");
  const [clienteNombre, setClienteNombre] = useState("");
  const [mesaId, setMesaId] = useState<number | "">("");
  const [metodoPago, setMetodoPago] = useState<"EFECTIVO" | "YAPE" | "TARJETA">("EFECTIVO");
  const [itemsTicket, setItemsTicket] = useState<ItemTicket[]>([]);
  const [enviando, setEnviando] = useState(false);
  const tipoAtencionActivo = canalesDisponibles.includes(tipoAtencion)
    ? tipoAtencion
    : canalesDisponibles[0] ?? "SALON";

  function cerrarDrawer() {
    setVistaMovil("CATALOGO");
    onCerrar();
  }

  useEffect(() => {
    if (!abierto) return;

    let cancelado = false;

    async function cargar() {
      setCargando(true);
      try {
        const [menuData, catData] = await Promise.all([
          apiRequest<Producto[]>("/productos/menu"),
          apiRequest<Categoria[]>("/productos/categorias"),
        ]);

        if (cancelado) return;
        setProductos(menuData);
        setCategorias(catData);

        try {
          const mesasData = await apiRequest<Mesa[]>("/mesas");
          if (cancelado) return;

          if (mesasData && mesasData.length > 0) {
            setMesas(mesasData);
            // Selecciona automáticamente la primera mesa libre
            const primeraLibre = mesasData.find((m) => !m.ocupada);
            setMesaId(primeraLibre ? primeraLibre.id : "");
          } else {
            const fallback = obtenerMesasPorDefecto();
            setMesas(fallback);
            setMesaId(fallback[0].id);
          }
        } catch {
          if (!cancelado) {
            const fallback = obtenerMesasPorDefecto();
            setMesas(fallback);
            setMesaId(fallback[0].id);
          }
        }
      } catch (err) {
        console.error("Error al cargar carta:", err);
      } finally {
        if (!cancelado) setCargando(false);
      }
    }

    cargar();

    return () => {
      cancelado = true;
    };
  }, [abierto]);

  useEffect(() => {
    if (!abierto) return;

    const overflowAnterior = document.body.style.overflow;
    document.body.style.overflow = "hidden";

    return () => {
      document.body.style.overflow = overflowAnterior;
    };
  }, [abierto]);

  useEffect(() => {
    if (!abierto) return;

    function manejarTecla(event: KeyboardEvent) {
      if (event.key === "Escape") {
        setVistaMovil("CATALOGO");
        onCerrar();
      }
    }

    window.addEventListener("keydown", manejarTecla);
    return () => {
      window.removeEventListener("keydown", manejarTecla);
    };
  }, [abierto, onCerrar]);

  function agregarAlTicket(prod: Producto, variante: Variante) {
    setItemsTicket((prev) => {
      const existeIndex = prev.findIndex(
        (item) => item.productoVarianteId === variante.id
      );

      if (existeIndex >= 0) {
        const copia = [...prev];
        copia[existeIndex].cantidad += 1;
        return copia;
      }

      return [
        ...prev,
        {
          productoVarianteId: variante.id,
          productoNombre: prod.nombre,
          tamano: variante.tamano,
          precioUnitario: Number(variante.precio),
          cantidad: 1,
          notas: "",
        },
      ];
    });
  }

  function cambiarCantidad(index: number, delta: number) {
    setItemsTicket((prev) => {
      const copia = [...prev];
      const nuevaCantidad = copia[index].cantidad + delta;
      if (nuevaCantidad <= 0) {
        return copia.filter((_, i) => i !== index);
      }
      copia[index].cantidad = nuevaCantidad;
      return copia;
    });
  }

  function cambiarNota(index: number, nota: string) {
    setItemsTicket((prev) => {
      const copia = [...prev];
      copia[index].notas = nota;
      return copia;
    });
  }

  function eliminarItem(index: number) {
    setItemsTicket((prev) => prev.filter((_, i) => i !== index));
  }

  const totalCalculado = itemsTicket.reduce(
    (acc, item) => acc + item.precioUnitario * item.cantidad,
    0
  );
  const cantidadProductos = itemsTicket.reduce((acc, item) => acc + item.cantidad, 0);

  async function handleConfirmarPedido() {
    if (itemsTicket.length === 0) {
      return alert("El ticket está vacío. Agrega al menos un producto.");
    }
    if (tipoAtencionActivo === "SALON") {
      if (!mesaId) {
        return alert("Selecciona una mesa disponible para abrir la comanda.");
      }
      const mesaElegida = mesas.find((m) => m.id === Number(mesaId));
      if (mesaElegida?.ocupada) {
        return alert(`La Mesa #${mesaElegida.numero} ya está ocupada. Suma productos a esa comanda desde el panel lateral.`);
      }
    }
    if (tipoAtencionActivo === "PARA_LLEVAR" && !clienteNombre.trim()) {
      return alert("Ingresa el nombre del cliente para llamarlo cuando esté listo.");
    }

    setEnviando(true);
    try {
      const payload = {
        canal: "SALON",
        mesaId: tipoAtencionActivo === "SALON" ? Number(mesaId) : null,
        clienteNombre: clienteNombre.trim() || undefined,
        metodoPago: tipoAtencionActivo === "PARA_LLEVAR" ? metodoPago : "EFECTIVO",
        items: itemsTicket.map((item) => ({
          productoVarianteId: item.productoVarianteId,
          cantidad: item.cantidad,
          notas: item.notas.trim() || undefined,
        })),
      };

      await apiRequest("/pedidos", {
        method: "POST",
        body: JSON.stringify(payload),
      });

      setItemsTicket([]);
      setClienteNombre("");
      onPedidoCreado();
      cerrarDrawer();
    } catch (err) {
      alert(err instanceof Error ? err.message : "Error al registrar el pedido");
    } finally {
      setEnviando(false);
    }
  }

  const categoriaSeleccionada = categorias.find((categoria) => categoria.id === categoriaActiva);
  const categoriaPrincipalSeleccionada = categoriaSeleccionada?.parentId
    ? categorias.find((categoria) => categoria.id === categoriaSeleccionada.parentId)
    : categoriaSeleccionada;
  const subcategoriasSeleccionadas = categorias.filter(
    (categoria) => categoria.parentId === categoriaPrincipalSeleccionada?.id
  );

  const productosFiltrados = productos.filter((p) => {
    const matchCat =
      categoriaActiva === "TODAS" ||
      (categoriaSeleccionada?.parentId
        ? p.categoriaId === categoriaSeleccionada.id
        : p.categoriaId === categoriaActiva ||
          subcategoriasSeleccionadas.some((subcategoria) => subcategoria.id === p.categoriaId));
    const matchNom = p.nombre.toLowerCase().includes(busqueda.toLowerCase());
    return matchCat && matchNom;
  });

  return (
    <div
      className={`fixed inset-0 z-50 transition-opacity duration-300 ease-in-out ${
        abierto ? "pointer-events-auto opacity-100" : "pointer-events-none opacity-0"
      }`}
    >
      <div
        onClick={cerrarDrawer}
        className="fixed inset-0 hidden bg-black/50 backdrop-blur-[2px] transition-opacity lg:block"
      />

      <div
        className={`absolute inset-0 flex h-[100dvh] w-full flex-col bg-white shadow-2xl transition-transform duration-300 ease-out dark:bg-gray-900 lg:inset-y-0 lg:left-auto lg:right-0 lg:h-full lg:max-w-5xl ${
          abierto ? "translate-x-0" : "translate-x-full"
        }`}
      >
        {/* Cabecera Principal */}
        <div className="flex shrink-0 items-center justify-between gap-3 border-b border-gray-100 px-4 py-3 dark:border-gray-800 sm:px-6 sm:py-4 lg:h-18 lg:py-0">
          <div className="min-w-0">
            <h2 className="text-lg font-bold text-gray-900 dark:text-white sm:text-xl">
              {tipoAtencionActivo === "SALON" ? "Apertura de Comanda en Mesa" : "Nuevo Pedido Para Llevar"}
            </h2>
            <p className="mt-0.5 text-xs text-gray-500 dark:text-gray-400 sm:text-sm">
              {tipoAtencionActivo === "SALON"
                ? "La comanda permanece abierta para sumar más consumos"
                : "Venta directa en mostrador con cobro al instante"}
            </p>
          </div>
          <button
            type="button"
            onClick={cerrarDrawer}
            aria-label="Cerrar creación de pedido"
            className="flex size-10 items-center justify-center rounded-lg text-gray-400 hover:bg-gray-100 hover:text-gray-600 dark:hover:bg-gray-800 dark:hover:text-white"
          >
            <CloseIcon className="size-6" />
          </button>
        </div>

        {/* Contenedor Dividido */}
        <div className="flex min-h-0 flex-1 flex-col overflow-hidden lg:flex-row">
          {/* PANEL IZQUIERDO: CATÁLOGO */}
          <div
            className={`min-h-0 flex-1 flex-col border-gray-100 p-4 pb-24 dark:border-gray-800 lg:w-7/12 lg:flex-none lg:border-e lg:p-5 lg:pb-5 ${
              vistaMovil === "CATALOGO" ? "flex" : "hidden lg:flex"
            }`}
          >
            <div className="flex items-center gap-2.5">
              <div className="relative flex-1">
                <SearchIcon className="absolute left-3.5 top-3 size-4.5 text-gray-400" />
                <input
                  type="search"
                  placeholder="Buscar pizza, snack, bebida..."
                  value={busqueda}
                  onChange={(e) => setBusqueda(e.target.value)}
                  className="h-11 w-full rounded-lg border border-gray-200 bg-white pl-10 pr-3.5 text-sm text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                />
              </div>
              <div className="flex rounded-lg border border-gray-200 bg-gray-50 p-1 dark:border-gray-700 dark:bg-gray-800">
                <button
                  type="button"
                  title="Vista Cuadrícula"
                  onClick={() => setModoVista("GRID")}
                  className={`flex size-9 items-center justify-center rounded-md ${
                    modoVista === "GRID"
                      ? "bg-white text-brand-600 shadow-xs dark:bg-gray-700 dark:text-white"
                      : "text-gray-400 hover:text-gray-700 dark:hover:text-gray-200"
                  }`}
                >
                  <GridViewIcon className="size-4.5" />
                </button>
                <button
                  type="button"
                  title="Vista Lista"
                  onClick={() => setModoVista("LISTA")}
                  className={`flex size-9 items-center justify-center rounded-md ${
                    modoVista === "LISTA"
                      ? "bg-white text-brand-600 shadow-xs dark:bg-gray-700 dark:text-white"
                      : "text-gray-400 hover:text-gray-700 dark:hover:text-gray-200"
                  }`}
                >
                  <ListViewIcon className="size-4.5" />
                </button>
              </div>
            </div>

            {/* Categorías */}
            <div className="mt-3.5 flex gap-2 overflow-x-auto pb-2 [&::-webkit-scrollbar]:h-1.5 [&::-webkit-scrollbar-track]:bg-transparent [&::-webkit-scrollbar-thumb]:rounded-full [&::-webkit-scrollbar-thumb]:bg-gray-300 dark:[&::-webkit-scrollbar-thumb]:bg-gray-700 hover:[&::-webkit-scrollbar-thumb]:bg-gray-400 dark:hover:[&::-webkit-scrollbar-thumb]:bg-gray-600">
              <button
                type="button"
                onClick={() => setCategoriaActiva("TODAS")}
                className={`whitespace-nowrap rounded-lg px-3.5 py-2 text-sm font-semibold transition ${
                  categoriaActiva === "TODAS"
                    ? "bg-brand-500 text-white shadow-xs"
                    : "bg-gray-100 text-gray-600 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-300"
                }`}
              >
                Todas
              </button>
              {categorias.filter((cat) => cat.parentId === null).map((cat) => (
                <button
                  key={cat.id}
                  type="button"
                  onClick={() => setCategoriaActiva(cat.id)}
                  className={`whitespace-nowrap rounded-lg px-3.5 py-2 text-sm font-semibold transition ${
                    categoriaSeleccionada?.id === cat.id || categoriaSeleccionada?.parentId === cat.id
                      ? "bg-brand-500 text-white shadow-xs"
                      : "bg-gray-100 text-gray-600 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-300"
                  }`}
                >
                  {cat.nombre}
                </button>
              ))}
            </div>

            {categoriaPrincipalSeleccionada && subcategoriasSeleccionadas.length > 0 && (
              <div className="flex gap-2 overflow-x-auto pb-1 [&::-webkit-scrollbar]:h-1 [&::-webkit-scrollbar-thumb]:rounded-full [&::-webkit-scrollbar-thumb]:bg-gray-300 dark:[&::-webkit-scrollbar-thumb]:bg-gray-700">
                <button
                  type="button"
                  onClick={() => setCategoriaActiva(categoriaPrincipalSeleccionada.id)}
                  className={`whitespace-nowrap rounded-lg px-3 py-1.5 text-xs font-semibold transition ${
                    categoriaActiva === categoriaPrincipalSeleccionada.id
                      ? "bg-brand-100 text-brand-700 dark:bg-brand-950/40 dark:text-brand-300"
                      : "bg-gray-100 text-gray-600 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-300"
                  }`}
                >
                  Todas las {categoriaPrincipalSeleccionada.nombre}
                </button>
                {subcategoriasSeleccionadas.map((subcategoria) => (
                  <button
                    key={subcategoria.id}
                    type="button"
                    onClick={() => setCategoriaActiva(subcategoria.id)}
                    className={`whitespace-nowrap rounded-lg px-3 py-1.5 text-xs font-semibold transition ${
                      categoriaActiva === subcategoria.id
                        ? "bg-brand-100 text-brand-700 dark:bg-brand-950/40 dark:text-brand-300"
                        : "bg-gray-100 text-gray-600 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-300"
                    }`}
                  >
                    {subcategoria.nombre}
                  </button>
                ))}
              </div>
            )}

            {/* Listado de Productos */}
            <div className="mt-4 flex-1 overflow-y-auto pr-1">
              {cargando ? (
                <p className="py-8 text-center text-sm text-gray-400">Cargando catálogo...</p>
              ) : productosFiltrados.length === 0 ? (
                <p className="py-8 text-center text-sm text-gray-400">No se encontraron productos.</p>
              ) : modoVista === "GRID" ? (
                <div className="columns-1 gap-3.5 pb-4 sm:columns-2">
                  {productosFiltrados.map((prod) => (
                    <div
                      key={prod.id}
                      className="mb-3.5 inline-block w-full break-inside-avoid rounded-xl border border-gray-200 bg-white p-4 shadow-xs dark:border-gray-800 dark:bg-gray-900"
                    >
                      <div>
                        <h4 className="text-sm font-bold text-gray-900 dark:text-white">
                          {prod.nombre}
                        </h4>
                        {prod.descripcion && (
                          <p className="mt-1 line-clamp-2 text-xs text-gray-400">
                            {prod.descripcion}
                          </p>
                        )}
                      </div>

                      <div className="mt-3.5 flex flex-wrap gap-1.5">
                        {prod.variantes.map((v) => (
                          <button
                            key={v.id}
                            type="button"
                            onClick={() => agregarAlTicket(prod, v)}
                            className="flex items-center gap-1.5 rounded-lg border border-brand-200 bg-brand-50/50 px-2.5 py-1.5 text-xs font-semibold text-brand-700 transition hover:bg-brand-500 hover:text-white dark:border-brand-900 dark:bg-brand-950/30 dark:text-brand-300 dark:hover:bg-brand-500 dark:hover:text-white"
                          >
                            <span>{v.tamano}</span>
                            <span className="font-bold">S/ {Number(v.precio).toFixed(2)}</span>
                          </button>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="divide-y divide-gray-100 rounded-xl border border-gray-200 bg-white dark:divide-gray-800 dark:border-gray-800 dark:bg-gray-900">
                  {productosFiltrados.map((prod) => (
                    <div
                      key={prod.id}
                      className="flex items-center justify-between p-3.5"
                    >
                      <div>
                        <div className="text-sm font-bold text-gray-900 dark:text-white">{prod.nombre}</div>
                        <div className="text-xs text-gray-400">{prod.descripcion || "Sin descripción"}</div>
                      </div>
                      <div className="flex flex-wrap gap-1.5">
                        {prod.variantes.map((v) => (
                          <button
                            key={v.id}
                            type="button"
                            onClick={() => agregarAlTicket(prod, v)}
                            className="rounded-lg border border-gray-200 bg-gray-50 px-2.5 py-1 text-xs font-medium text-gray-700 hover:border-brand-500 hover:bg-brand-50 hover:text-brand-600 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300"
                          >
                            {v.tamano}: S/ {Number(v.precio).toFixed(2)} +
                          </button>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* PANEL DERECHO: COMANDA / TICKET */}
          <div
            className={`min-h-0 flex-1 flex-col justify-between bg-gray-50/50 p-4 dark:bg-gray-900/50 lg:w-5/12 lg:flex-none lg:p-5.5 ${
              vistaMovil === "PEDIDO" ? "flex" : "hidden lg:flex"
            }`}
          >
            <div className="mb-3 flex shrink-0 items-center justify-between border-b border-gray-200 pb-3 dark:border-gray-800 lg:hidden">
              <div>
                <h3 className="text-base font-bold text-gray-900 dark:text-white">Tu pedido</h3>
                <p className="text-xs text-gray-500 dark:text-gray-400">
                  {cantidadProductos} {cantidadProductos === 1 ? "producto" : "productos"}
                </p>
              </div>
              <button
                type="button"
                onClick={() => setVistaMovil("CATALOGO")}
                className="rounded-lg border border-gray-200 bg-white px-3 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-100 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-200"
              >
                Volver al catálogo
              </button>
            </div>

            <div className="space-y-4">
              {/* Selector de Modalidad */}
              <div>
                <label className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                  Tipo de Atención
                </label>
                <div className={`mt-1.5 grid gap-2 ${canalesDisponibles.length > 1 ? "grid-cols-2" : "grid-cols-1"}`}>
                  {canalesDisponibles.includes("SALON") && (
                    <button
                      type="button"
                      onClick={() => setTipoAtencion("SALON")}
                      className={`flex items-center justify-center gap-2 rounded-lg py-2.5 text-sm font-bold transition ${
                        tipoAtencionActivo === "SALON"
                          ? "bg-brand-500 text-white shadow-xs"
                          : "border border-gray-200 bg-white text-gray-600 hover:bg-gray-100 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300"
                      }`}
                    >
                      <TableIcon className="size-4.5" />
                      En Mesa
                    </button>
                  )}
                  {canalesDisponibles.includes("PARA_LLEVAR") && (
                    <button
                      type="button"
                      onClick={() => setTipoAtencion("PARA_LLEVAR")}
                      className={`flex items-center justify-center gap-2 rounded-lg py-2.5 text-sm font-bold transition ${
                        tipoAtencionActivo === "PARA_LLEVAR"
                          ? "bg-brand-500 text-white shadow-xs"
                          : "border border-gray-200 bg-white text-gray-600 hover:bg-gray-100 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300"
                      }`}
                    >
                      <TakeoutIcon className="size-4.5" />
                      Para Llevar
                    </button>
                  )}
                </div>
              </div>

              {/* Nombre Cliente y Selector de Mesa Inteligente */}
              <div className="grid grid-cols-2 gap-2.5">
                <div className={tipoAtencionActivo === "PARA_LLEVAR" ? "col-span-2" : "col-span-1"}>
                  <label className="flex items-center gap-1.5 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                    <UserIcon className="size-3.5" />
                    Cliente {tipoAtencionActivo === "PARA_LLEVAR" ? "*" : "(Opcional)"}
                  </label>
                  <input
                    type="text"
                    required={tipoAtencionActivo === "PARA_LLEVAR"}
                    placeholder="Ej: Carlos..."
                    value={clienteNombre}
                    onChange={(e) => setClienteNombre(e.target.value)}
                    className="mt-1 h-10 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  />
                </div>

                {tipoAtencionActivo === "SALON" && (
                  <div>
                    <label className="flex items-center gap-1.5 text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                      <TableIcon className="size-3.5" />
                      Mesa *
                    </label>
                    <select
                      value={mesaId}
                      onChange={(e) => setMesaId(e.target.value ? Number(e.target.value) : "")}
                      className="mt-1 h-10 w-full rounded-lg border border-gray-300 bg-white px-2.5 text-xs font-bold text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                    >
                      <option value="">Selecciona mesa libre...</option>
                      {mesas.map((m) => (
                        <option
                          key={m.id}
                          value={m.id}
                          disabled={m.ocupada}
                          className={m.ocupada ? "text-gray-400 bg-gray-100 dark:bg-gray-800 font-normal" : "font-bold text-gray-900"}
                        >
                          Mesa #{m.numero} {m.ocupada ? `— OCUPADA (S/ ${Number(m.pedidoActivo?.total || 0).toFixed(2)})` : "— LIBRE"}
                        </option>
                      ))}
                    </select>
                  </div>
                )}
              </div>

              {/* Método de Pago: Solo si es para llevar */}
              {tipoAtencionActivo === "PARA_LLEVAR" ? (
                <div>
                  <label className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                    Método de Pago Inmediato
                  </label>
                  <div className="mt-1.5 grid grid-cols-3 gap-2">
                    {(["EFECTIVO", "YAPE", "TARJETA"] as const).map((metodo) => (
                      <button
                        key={metodo}
                        type="button"
                        onClick={() => setMetodoPago(metodo)}
                        className={`rounded-lg py-2 text-xs font-bold tracking-wider transition ${
                          metodoPago === metodo
                            ? "bg-brand-500 text-white shadow-xs"
                            : "border border-gray-200 bg-white text-gray-600 hover:bg-gray-100 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300"
                        }`}
                      >
                        {metodo}
                      </button>
                    ))}
                  </div>
                </div>
              ) : (
                <div className="rounded-lg border border-blue-100 bg-blue-50/60 p-3 text-xs text-blue-700 dark:border-blue-900/30 dark:bg-blue-950/20 dark:text-blue-300">
                  Para pedidos en local.
                </div>
              )}
            </div>

            {/* Lista del Ticket */}
            <div className="my-3.5 min-h-0 flex-1 overflow-y-auto rounded-xl border border-gray-200 bg-white p-3.5 dark:border-gray-800 dark:bg-gray-900">
              {itemsTicket.length === 0 ? (
                <div className="flex h-full flex-col items-center justify-center text-center">
                  <TakeoutIcon className="size-9 text-gray-300 dark:text-gray-600" />
                  <p className="mt-2 text-sm font-medium text-gray-400">
                    Selecciona un producto y tamaño para agregarlo a la comanda.
                  </p>
                </div>
              ) : (
                <div className="space-y-3">
                  {itemsTicket.map((item, index) => (
                    <div
                      key={index}
                      className="border-b border-gray-100 pb-3 last:border-b-0 last:pb-0 dark:border-gray-800"
                    >
                      <div className="flex items-start justify-between">
                        <div>
                          <span className="text-sm font-bold text-gray-800 dark:text-white">
                            {item.productoNombre}
                          </span>
                          <span className="ml-1.5 text-xs font-medium text-gray-400">
                            ({item.tamano})
                          </span>
                        </div>
                        <span className="text-sm font-bold text-gray-900 dark:text-white">
                          S/ {(item.precioUnitario * item.cantidad).toFixed(2)}
                        </span>
                      </div>

                      <div className="mt-2 flex items-center justify-between gap-2.5">
                        <div className="flex items-center rounded-lg border border-gray-200 dark:border-gray-700">
                          <button
                            type="button"
                            onClick={() => cambiarCantidad(index, -1)}
                            className="flex size-7 items-center justify-center text-sm font-bold text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800"
                          >
                            -
                          </button>
                          <span className="px-2.5 text-sm font-bold text-gray-800 dark:text-white">
                            {item.cantidad}
                          </span>
                          <button
                            type="button"
                            onClick={() => cambiarCantidad(index, 1)}
                            className="flex size-7 items-center justify-center text-sm font-bold text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800"
                          >
                            +
                          </button>
                        </div>

                        <input
                          type="text"
                          placeholder="Añadir comentario (opcional)"
                          value={item.notas}
                          onChange={(e) => cambiarNota(index, e.target.value)}
                          className="h-8 flex-1 rounded border border-gray-200 px-2.5 text-xs text-gray-700 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                        />

                        <button
                          type="button"
                          title="Quitar producto"
                          onClick={() => eliminarItem(index)}
                          className="flex size-8 items-center justify-center rounded text-gray-400 hover:bg-red-50 hover:text-red-500 dark:hover:bg-red-950/20"
                        >
                          <TrashIcon className="size-4" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Total y Confirmar */}
            <div className="border-t border-gray-200 pt-3.5 dark:border-gray-800">
              <div className="flex items-center justify-between">
                <span className="text-sm font-semibold text-gray-500 dark:text-gray-400">Total a Pagar:</span>
                <span className="text-2xl font-black text-gray-900 dark:text-white">
                  S/ {totalCalculado.toFixed(2)}
                </span>
              </div>

              <button
                type="button"
                onClick={handleConfirmarPedido}
                disabled={enviando || itemsTicket.length === 0}
                className="mt-3.5 flex w-full items-center justify-center gap-2 rounded-xl bg-brand-500 py-3.5 text-base font-bold text-white shadow-md transition hover:bg-brand-600 disabled:opacity-40"
              >
                {enviando
                  ? "Registrando pedido..."
                  : tipoAtencionActivo === "SALON"
                  ? "Abrir Comanda en Mesa"
                  : "Cobrar y Confirmar Pedido"}
              </button>
            </div>
          </div>
        </div>

        {vistaMovil === "CATALOGO" && (
          <div className="absolute inset-x-0 bottom-0 z-10 border-t border-gray-200 bg-white/95 p-3 pb-[max(0.75rem,env(safe-area-inset-bottom))] shadow-[0_-8px_24px_rgba(15,23,42,0.08)] backdrop-blur-sm dark:border-gray-800 dark:bg-gray-900/95 sm:p-4 lg:hidden">
            <button
              type="button"
              onClick={() => setVistaMovil("PEDIDO")}
              disabled={cantidadProductos === 0}
              className="flex w-full items-center justify-between rounded-xl bg-brand-500 px-4 py-3 text-left text-white shadow-sm transition hover:bg-brand-600 disabled:cursor-not-allowed disabled:opacity-50"
            >
              <span>
                <span className="block text-sm font-bold">
                  {cantidadProductos === 0 ? "Agrega productos para continuar" : "Revisar pedido"}
                </span>
                {cantidadProductos > 0 && (
                  <span className="text-xs text-white/80">
                    {cantidadProductos} {cantidadProductos === 1 ? "producto" : "productos"}
                  </span>
                )}
              </span>
              <span className="text-base font-black">S/ {totalCalculado.toFixed(2)}</span>
            </button>
          </div>
        )}
      </div>
    </div>
  );
}