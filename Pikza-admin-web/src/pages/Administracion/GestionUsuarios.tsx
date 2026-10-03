// src/pages/Administracion/GestionUsuarios.tsx
import { useEffect, useState } from "react";
import { apiRequest } from "@/services/api";
import { useAuth } from "@/context/AuthContext";

// --- ICONOS VECTORIALES PROFESIONALES ---
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

function PlusIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="2" {...props}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M10 4v12m-6-6h12" />
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

function EditIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6" {...props}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M11.05 3l5.95 5.95M3 17l1.05-4.95L14.1 2.05a2.1 2.1 0 0 1 2.97 2.97L7.02 15.07 3 17Z" />
    </svg>
  );
}

function MapPinIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6" {...props}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M10 2a6 6 0 0 0-6 6c0 4.5 6 10 6 10s6-5.5 6-10a6 6 0 0 0-6-6Zm0 8a2 2 0 1 1 0-4 2 2 0 0 1 0 4Z" />
    </svg>
  );
}

type Direccion = {
  id: number;
  zona: string;
  referencia?: string | null;
  lat: number;
  lng: number;
};

type UsuarioItem = {
  id: number;
  nombre: string;
  email: string;
  telefono?: string | null;
  rol: "ADMIN" | "MOZO" | "REPARTIDOR" | "PERSONALIZADO" | "CLIENTE";
  permisos: string[];
  capacidadPedidos?: number | null;
  createdAt: string;
  direcciones?: Direccion[];
  totalPedidos?: number;
};

const LISTA_PERMISOS = [
  { clave: "pedidos:ver", label: "Ver pedidos" },
  { clave: "pedidos:crear", label: "Registrar pedidos y agregar consumos a comandas" },
  { clave: "pedidos:cobrar", label: "Cobrar y finalizar pedidos pagados" },
];

const CANALES_PEDIDO = [
  { clave: "pedidos:canal:SALON", label: "En salón" },
  { clave: "pedidos:canal:PARA_LLEVAR", label: "Para llevar" },
  { clave: "pedidos:canal:DELIVERY", label: "Delivery" },
];

const GRUPOS_PERMISOS_CONFIGURABLES = [
  { titulo: "Pedidos", permisos: [...LISTA_PERMISOS, ...CANALES_PEDIDO] },
  {
    titulo: "Mesas",
    permisos: [
      { clave: "mesas:ver", label: "Consultar mesas y su estado" },
      { clave: "mesas:admin", label: "Crear, editar y eliminar mesas" },
    ],
  },
  {
    titulo: "Catálogo",
    permisos: [{ clave: "productos:admin", label: "Gestionar productos, categorías y agregados" }],
  },
  {
    titulo: "Repartidores",
    permisos: [{ clave: "reparto:gestion", label: "Consultar y asignar repartidores" }],
  },
  {
    titulo: "Usuarios",
    permisos: [{ clave: "usuarios:admin", label: "Gestionar usuarios excepto cuentas Administrador" }],
  },
];

function etiquetaPermiso(permiso: string) {
  if (permiso === "pedidos:ver") return "Ver pedidos";
  if (permiso === "pedidos:crear") return "Registrar y continuar";
  if (permiso === "pedidos:cobrar") return "Cobrar y finalizar";
  if (permiso === "mesas:ver") return "Ver mesas";
  if (permiso === "mesas:admin") return "Gestionar mesas";
  if (permiso === "productos:admin") return "Gestionar catálogo";
  if (permiso === "reparto:gestion") return "Gestionar repartidores";
  if (permiso === "usuarios:admin") return "Gestionar usuarios";
  return CANALES_PEDIDO.find((canal) => canal.clave === permiso)?.label ?? permiso;
}

export default function GestionUsuarios() {
  const { usuario: usuarioActual } = useAuth();
  const [usuarios, setUsuarios] = useState<UsuarioItem[]>([]);
  const [cargando, setCargando] = useState(true);
  const [busqueda, setBusqueda] = useState("");
  const [filtroRol, setFiltroRol] = useState<"TODOS" | "STAFF" | "CLIENTE">("TODOS");
  const [error, setError] = useState("");

  // Drawer
  const [drawerAbierto, setDrawerAbierto] = useState(false);
  const [usuarioEnEdicion, setUsuarioEnEdicion] = useState<UsuarioItem | null>(null);
  const [guardando, setGuardando] = useState(false);

  // Formulario
  const [nombre, setNombre] = useState("");
  const [email, setEmail] = useState("");
  const [telefono, setTelefono] = useState("");
  const [password, setPassword] = useState("");
  const [rol, setRol] = useState<"ADMIN" | "MOZO" | "REPARTIDOR" | "PERSONALIZADO">("MOZO");
  const [capacidadPedidos, setCapacidadPedidos] = useState(2);
  const [permisosSeleccionados, setPermisosSeleccionados] = useState<string[]>([]);

  useEffect(() => {
    cargarUsuarios();
  }, []);

  async function cargarUsuarios() {
    setCargando(true);
    setError("");
    try {
      const data = await apiRequest<UsuarioItem[]>("/auth/usuarios");
      setUsuarios(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error al cargar los usuarios");
    } finally {
      setCargando(false);
    }
  }

  function abrirCrear() {
    setUsuarioEnEdicion(null);
    setNombre("");
    setEmail("");
    setTelefono("");
    setPassword("");
    setRol("MOZO");
    setCapacidadPedidos(2);
    setPermisosSeleccionados(["pedidos:ver", "pedidos:crear", "pedidos:canal:SALON"]);
    setDrawerAbierto(true);
  }

  function abrirEditar(u: UsuarioItem) {
    setUsuarioEnEdicion(u);
    setNombre(u.nombre);
    setEmail(u.email);
    setTelefono(u.telefono || "");
    setPassword("");
    setRol(u.rol === "CLIENTE" ? "MOZO" : u.rol);
    setCapacidadPedidos(u.capacidadPedidos ?? 2);
    setPermisosSeleccionados(u.permisos || []);
    setDrawerAbierto(true);
  }

  function togglePermiso(clave: string) {
    setPermisosSeleccionados((prev) => {
      if (clave === "pedidos:crear" || clave === "pedidos:cobrar") {
        return prev.includes(clave)
          ? prev.filter((permiso) => permiso !== clave)
          : [...new Set([...prev, "pedidos:ver", clave])];
      }

      if (clave === "pedidos:ver" && prev.includes(clave)) {
        return prev.filter((permiso) =>
          permiso !== "pedidos:ver" &&
          permiso !== "pedidos:crear" &&
          permiso !== "pedidos:cobrar" &&
          !permiso.startsWith("pedidos:canal:")
        );
      }

      if (clave.startsWith("pedidos:canal:")) {
        if (prev.includes(clave)) return prev.filter((permiso) => permiso !== clave);
        return [...new Set([...prev, "pedidos:ver", clave])];
      }

      if (clave === "mesas:admin" && !prev.includes(clave)) {
        return [...new Set([...prev, "mesas:ver", clave])];
      }

      if (prev.includes(clave)) return prev.filter((permiso) => permiso !== clave);
      return [...new Set([...prev, clave])];
    });
  }

  function toggleCanal(clave: string) {
    setPermisosSeleccionados((prev) => {
      const seleccionados = prev.includes(clave)
        ? prev.filter((permiso) => permiso !== clave)
        : [...prev, clave];
      return seleccionados.includes("pedidos:ver")
        ? seleccionados
        : [...seleccionados, "pedidos:ver"];
    });
  }

  function toggleTodosLosCanales() {
    const claves = CANALES_PEDIDO.map((canal) => canal.clave);
    const todosSeleccionados = claves.every((clave) => permisosSeleccionados.includes(clave));
    setPermisosSeleccionados((prev) => {
      const sinCanales = prev.filter((permiso) => !permiso.startsWith("pedidos:canal:"));
      return todosSeleccionados
        ? sinCanales
        : [...new Set([...sinCanales, "pedidos:ver", ...claves])];
    });
  }

  function cambiarRol(nuevoRol: "ADMIN" | "MOZO" | "REPARTIDOR" | "PERSONALIZADO") {
    setRol(nuevoRol);
    setPermisosSeleccionados(
      nuevoRol === "MOZO"
        ? ["pedidos:ver", "pedidos:crear", "pedidos:canal:SALON"]
        : [],
    );
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setGuardando(true);

    try {
      if (usuarioEnEdicion) {
        const esCliente = usuarioEnEdicion.rol === "CLIENTE";
        const payload: Record<string, unknown> = {
          nombre: nombre.trim(),
          email: email.trim(),
          telefono: telefono.trim() || undefined,
        };

        // Si es STAFF, se le permite actualizar rol y permisos
        if (!esCliente) {
          payload.rol = rol;
          payload.permisos = rol === "ADMIN" ? ["*"] : permisosSeleccionados;
          if (rol === "REPARTIDOR") payload.capacidadPedidos = capacidadPedidos;
        }

        if (password.trim()) {
          payload.password = password.trim();
        }

        await apiRequest(`/auth/usuarios/${usuarioEnEdicion.id}`, {
          method: "PUT",
          body: JSON.stringify(payload),
        });
      } else {
        const payload = {
          nombre: nombre.trim(),
          email: email.trim(),
          password: password.trim(),
          telefono: telefono.trim() || undefined,
          rol,
          permisos: rol === "ADMIN" ? ["*"] : permisosSeleccionados,
          ...(rol === "REPARTIDOR" && { capacidadPedidos }),
        };

        await apiRequest("/auth/staff", {
          method: "POST",
          body: JSON.stringify(payload),
        });
      }

      setDrawerAbierto(false);
      await cargarUsuarios();
    } catch (err) {
      alert(err instanceof Error ? err.message : "Error al guardar usuario");
    } finally {
      setGuardando(false);
    }
  }

  async function handleEliminar(u: UsuarioItem) {
    if (u.id === usuarioActual?.id) {
      return alert("No puedes eliminar tu propia cuenta");
    }
    if (!confirm(`¿Estás seguro de eliminar a ${u.nombre}?`)) return;

    try {
      await apiRequest(`/auth/usuarios/${u.id}`, { method: "DELETE" });
      setUsuarios((prev) => prev.filter((item) => item.id !== u.id));
    } catch (err) {
      alert(err instanceof Error ? err.message : "No se pudo eliminar al usuario");
    }
  }

  const usuariosFiltrados = usuarios.filter((u) => {
    const matchBusqueda =
      u.nombre.toLowerCase().includes(busqueda.toLowerCase()) ||
      u.email.toLowerCase().includes(busqueda.toLowerCase()) ||
      (u.telefono && u.telefono.includes(busqueda));

    if (!matchBusqueda) return false;

    if (filtroRol === "STAFF") return u.rol !== "CLIENTE";
    if (filtroRol === "CLIENTE") return u.rol === "CLIENTE";
    return true;
  });

  return (
    <div className="space-y-6">
      {/* Encabezado */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="text-sm text-gray-500 dark:text-gray-400">Seguridad & Personal</p>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Gestión de Usuarios
          </h1>
        </div>

        <button
          type="button"
          onClick={abrirCrear}
          className="flex items-center gap-2 rounded-xl bg-brand-500 px-4 py-2.5 text-sm font-bold text-white shadow-sm transition hover:bg-brand-600"
        >
          <PlusIcon className="size-4.5" />
          Nuevo Personal
        </button>
      </div>

      {error && (
        <div className="rounded-xl bg-red-50 p-4 text-sm text-red-600 dark:bg-red-950/20 dark:text-red-400">
          {error}
        </div>
      )}

      {/* Pestañas y Buscador */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div className="flex gap-2">
          {(["TODOS", "STAFF", "CLIENTE"] as const).map((pestana) => (
            <button
              key={pestana}
              type="button"
              onClick={() => setFiltroRol(pestana)}
              className={`rounded-lg px-4 py-2 text-sm font-semibold transition ${
                filtroRol === pestana
                  ? "bg-brand-500 text-white shadow-xs"
                  : "bg-white text-gray-600 hover:bg-gray-50 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
              }`}
            >
              {pestana === "TODOS" ? "Todos" : pestana === "STAFF" ? "Equipo / Staff" : "Clientes"}
            </button>
          ))}
        </div>

        <div className="relative w-full md:w-72">
          <SearchIcon className="absolute left-3.5 top-3 size-4.5 text-gray-400" />
          <input
            type="search"
            placeholder="Buscar por nombre, email..."
            value={busqueda}
            onChange={(e) => setBusqueda(e.target.value)}
            className="h-10.5 w-full rounded-lg border border-gray-300 bg-white pl-10 pr-3.5 text-sm text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
          />
        </div>
      </div>

      {/* Tabla */}
      <div className="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-800 dark:bg-gray-900">
        <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-800">
          <thead className="bg-gray-50 text-left text-xs font-bold uppercase tracking-wider text-gray-500 dark:bg-gray-800/50 dark:text-gray-400">
            <tr>
              <th className="px-5 py-4">Usuario</th>
              <th className="px-5 py-4">Tipo / Rol</th>
              <th className="px-5 py-4">Ubicación / Permisos</th>
              <th className="px-5 py-4">Teléfono</th>
              <th className="px-5 py-4 text-right">Acciones</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 text-sm dark:divide-gray-800">
            {cargando ? (
              <tr>
                <td colSpan={5} className="py-12 text-center text-gray-400">
                  Cargando usuarios...
                </td>
              </tr>
            ) : usuariosFiltrados.length === 0 ? (
              <tr>
                <td colSpan={5} className="py-12 text-center text-gray-400">
                  No se encontraron usuarios.
                </td>
              </tr>
            ) : (
              usuariosFiltrados.map((u) => (
                <tr key={u.id} className="hover:bg-gray-50/50 dark:hover:bg-white/[0.02]">
                  <td className="px-5 py-4 font-medium text-gray-900 dark:text-white">
                    <div className="font-bold">{u.nombre}</div>
                    <div className="text-xs text-gray-400">{u.email}</div>
                  </td>
                  <td className="px-5 py-4">
                    <span
                      className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-bold ${
                        u.rol === "ADMIN"
                          ? "bg-purple-100 text-purple-700 dark:bg-purple-950/40 dark:text-purple-300"
                          : u.rol === "MOZO"
                          ? "bg-blue-100 text-blue-700 dark:bg-blue-950/40 dark:text-blue-300"
                          : u.rol === "REPARTIDOR"
                          ? "bg-amber-100 text-amber-700 dark:bg-amber-950/40 dark:text-amber-300"
                          : u.rol === "PERSONALIZADO"
                          ? "bg-teal-100 text-teal-700 dark:bg-teal-950/40 dark:text-teal-300"
                          : "bg-emerald-100 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300"
                      }`}
                    >
                      {u.rol === "CLIENTE" ? "Cliente App" : u.rol === "PERSONALIZADO" ? "Configurable" : u.rol}
                    </span>
                    {u.rol === "REPARTIDOR" && u.capacidadPedidos && (
                      <div className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                        Máximo {u.capacidadPedidos} pedidos activos
                      </div>
                    )}
                  </td>
                  <td className="px-5 py-4">
                    {/* Si es cliente, mostramos sus direcciones */}
                    {u.rol === "CLIENTE" ? (
                      u.direcciones && u.direcciones.length > 0 ? (
                        <div className="flex items-center gap-1.5 text-xs text-gray-600 dark:text-gray-300">
                          <MapPinIcon className="size-4 text-emerald-500 shrink-0" />
                          <span className="truncate max-w-xs">{u.direcciones[0].zona}</span>
                          {u.direcciones.length > 1 && (
                            <span className="rounded bg-gray-100 px-1.5 py-0.2 text-[10px] dark:bg-gray-800">
                              +{u.direcciones.length - 1}
                            </span>
                          )}
                        </div>
                      ) : (
                        <span className="text-xs text-gray-400">Sin dirección registrada</span>
                      )
                    ) : u.rol === "ADMIN" ? (
                      <span className="text-xs font-semibold text-purple-500">Acceso Total (*)</span>
                    ) : u.permisos && u.permisos.length > 0 ? (
                      <div className="flex flex-wrap gap-1">
                        {u.permisos.map((p) => (
                          <span
                            key={p}
                            className="rounded bg-gray-100 px-2 py-0.5 text-[11px] font-medium text-gray-700 dark:bg-gray-800 dark:text-gray-300"
                          >
                            {etiquetaPermiso(p)}
                          </span>
                        ))}
                      </div>
                    ) : (
                      <span className="text-xs text-gray-400">Sin permisos especiales</span>
                    )}
                  </td>
                  <td className="px-5 py-4 text-gray-600 dark:text-gray-300">
                    {u.telefono || "-"}
                  </td>
                  <td className="px-5 py-4 text-right">
                    <div className="flex items-center justify-end gap-3">
                      {(usuarioActual?.rol === "ADMIN" || u.rol !== "ADMIN") && (
                        <button
                          type="button"
                          onClick={() => abrirEditar(u)}
                          className="flex items-center gap-1 text-xs font-bold text-brand-500 hover:underline"
                        >
                          <EditIcon className="size-3.5" />
                          Editar
                        </button>
                      )}
                      {u.id !== usuarioActual?.id && (
                        (usuarioActual?.rol === "ADMIN" || u.rol !== "ADMIN") && (
                          <button
                            type="button"
                            onClick={() => handleEliminar(u)}
                            className="flex items-center gap-1 text-xs font-semibold text-red-500 hover:underline"
                          >
                            <TrashIcon className="size-3.5" />
                            Eliminar
                          </button>
                        )
                      )}
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* ======================================================== */}
      {/* DRAWER DERECHO: FORMULARIO DINÁMICO                       */}
      {/* ======================================================== */}
      <div
        className={`fixed inset-0 z-50 transition-opacity duration-300 ease-in-out ${
          drawerAbierto ? "pointer-events-auto opacity-100" : "pointer-events-none opacity-0"
        }`}
      >
        <div
          onClick={() => setDrawerAbierto(false)}
          className="fixed inset-0 bg-black/60 backdrop-blur-[2px] transition-opacity"
        />

        <div
          className={`absolute inset-y-0 right-0 flex w-full max-w-lg flex-col bg-white shadow-2xl transition-transform duration-300 ease-out dark:bg-gray-900 ${
            drawerAbierto ? "translate-x-0" : "translate-x-full"
          }`}
        >
          {/* Header */}
          <div className="flex items-center justify-between border-b border-gray-100 px-6 py-4.5 dark:border-gray-800">
            <div>
              <h2 className="text-lg font-bold text-gray-900 dark:text-white">
                {usuarioEnEdicion
                  ? usuarioEnEdicion.rol === "CLIENTE"
                    ? "Detalles de Cliente"
                    : "Modificar Personal"
                  : "Crear Nuevo Personal"}
              </h2>
              <p className="text-xs text-gray-500 dark:text-gray-400">
                {usuarioEnEdicion
                  ? `Cuenta: ${usuarioEnEdicion.email}`
                  : "Registra credenciales y permisos del empleado"}
              </p>
            </div>
            <button
              type="button"
              onClick={() => setDrawerAbierto(false)}
              className="flex size-9 items-center justify-center rounded-lg text-gray-400 hover:bg-gray-100 hover:text-gray-600 dark:hover:bg-gray-800 dark:hover:text-white"
            >
              <CloseIcon className="size-5" />
            </button>
          </div>

          {/* Formulario */}
          <form onSubmit={handleSubmit} className="flex flex-1 flex-col justify-between overflow-y-auto">
            <div className="space-y-4.5 p-6">
              <div>
                <label className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                  Nombres y Apellidos *
                </label>
                <input
                  type="text"
                  required
                  placeholder="Ej: Juan Mendoza"
                  value={nombre}
                  onChange={(e) => setNombre(e.target.value)}
                  className="mt-1.5 h-10 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                    Correo Electrónico *
                  </label>
                  <input
                    type="email"
                    required
                    placeholder="correo@ejemplo.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="mt-1.5 h-10 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  />
                </div>

                <div>
                  <label className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                    Teléfono
                  </label>
                  <input
                    type="tel"
                    placeholder="999888777"
                    value={telefono}
                    onChange={(e) => setTelefono(e.target.value)}
                    className="mt-1.5 h-10 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  />
                </div>
              </div>

              <div>
                <label className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                  {usuarioEnEdicion ? "Resetear Contraseña (dejar vacío si no cambia)" : "Contraseña de Acceso *"}
                </label>
                <input
                  type="password"
                  required={!usuarioEnEdicion}
                  placeholder="Mínimo 6 caracteres"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="mt-1.5 h-10 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                />
              </div>

              {/* SI ES CLIENTE: Mostramos Direcciones y pedidos (SELLADO DE ROLES) */}
              {usuarioEnEdicion && usuarioEnEdicion.rol === "CLIENTE" ? (
                <div className="rounded-xl border border-gray-100 bg-gray-50/70 p-4 dark:border-gray-800 dark:bg-gray-800/40 space-y-3">
                  <div className="flex items-center justify-between">
                    <h4 className="text-xs font-bold uppercase tracking-wider text-gray-700 dark:text-gray-300">
                      Direcciones de Entrega Registradas
                    </h4>
                    <span className="text-xs text-brand-600 font-semibold">
                      {usuarioEnEdicion.totalPedidos || 0} pedidos realizados
                    </span>
                  </div>

                  {usuarioEnEdicion.direcciones && usuarioEnEdicion.direcciones.length > 0 ? (
                    <div className="space-y-2">
                      {usuarioEnEdicion.direcciones.map((d) => (
                        <div
                          key={d.id}
                          className="rounded-lg border border-gray-200 bg-white p-3 text-xs dark:border-gray-700 dark:bg-gray-900"
                        >
                          <div className="font-bold text-gray-900 dark:text-white">{d.zona}</div>
                          {d.referencia && (
                            <p className="mt-0.5 text-gray-500 dark:text-gray-400">Ref: {d.referencia}</p>
                          )}
                          {d.lat && d.lng && (
                            <a
                              href={`https://www.google.com/maps?q=${d.lat},${d.lng}`}
                              target="_blank"
                              rel="noreferrer"
                              className="mt-1.5 inline-flex items-center gap-1 font-semibold text-brand-500 hover:underline"
                            >
                              <MapPinIcon className="size-3.5" />
                              Ver en Google Maps
                            </a>
                          )}
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-xs text-gray-400">El cliente aún no ha guardado direcciones en la app.</p>
                  )}
                </div>
              ) : (
                /* SI ES PERSONAL (STAFF): Mostramos Selector de Rol y Permisos */
                <>
                  <div>
                    <label className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                      Rol del Personal
                    </label>
                    <select
                      value={rol}
                      onChange={(e) => cambiarRol(e.target.value as "ADMIN" | "MOZO" | "REPARTIDOR" | "PERSONALIZADO")}
                      className="mt-1.5 h-10 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm font-semibold text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                    >
                      <option value="MOZO">Mozo (Salón y pedidos)</option>
                      <option value="REPARTIDOR">Repartidor (Delivery)</option>
                      <option value="PERSONALIZADO">Configurable (permisos por módulo)</option>
                      {usuarioActual?.rol === "ADMIN" && (
                        <option value="ADMIN">Administrador (Control total)</option>
                      )}
                    </select>
                  </div>

                  {rol === "REPARTIDOR" && (
                    <div className="rounded-xl border border-amber-200 bg-amber-50/70 p-4 dark:border-amber-900/50 dark:bg-amber-950/20">
                      <label className="text-xs font-bold uppercase tracking-wider text-amber-900 dark:text-amber-300">
                        Capacidad de pedidos activos
                      </label>
                      <input
                        type="number"
                        min={1}
                        step={1}
                        required
                        value={capacidadPedidos}
                        onChange={(e) => setCapacidadPedidos(Number(e.target.value))}
                        className="mt-1.5 h-10 w-full rounded-lg border border-amber-300 bg-white px-3 text-sm text-gray-800 outline-none focus:border-brand-500 dark:border-amber-800 dark:bg-gray-900 dark:text-white"
                      />
                      <p className="mt-1.5 text-xs text-amber-800 dark:text-amber-300">
                        Máximo de pedidos sin entregar que puede tener asignados. La disponibilidad se controla por separado.
                      </p>
                    </div>
                  )}

                  {rol === "MOZO" && (
                    <div className="rounded-xl border border-gray-100 bg-gray-50/70 p-4 dark:border-gray-800 dark:bg-gray-800/40">
                      <h4 className="text-xs font-bold uppercase tracking-wider text-gray-700 dark:text-gray-300">
                        Permisos de pedidos
                      </h4>
                      <p className="mt-0.5 text-xs text-gray-500">
                        Selecciona qué canales podrá consultar y gestionar este mozo.
                      </p>

                      <div className="mt-3 space-y-2.5">
                        {LISTA_PERMISOS.map((perm) => (
                          <label key={perm.clave} className="flex cursor-pointer items-center gap-3">
                            <input
                              type="checkbox"
                              checked={permisosSeleccionados.includes(perm.clave)}
                              onChange={() => togglePermiso(perm.clave)}
                              className="size-4.5 rounded border-gray-300 text-brand-500 focus:ring-brand-400"
                            />
                            <span className="text-xs font-medium text-gray-700 dark:text-gray-200">
                              {perm.label}
                            </span>
                          </label>
                        ))}
                      </div>
                      <div className="mt-4 border-t border-gray-200 pt-3 dark:border-gray-700">
                        <label className="flex cursor-pointer items-center gap-3">
                          <input
                            type="checkbox"
                            checked={CANALES_PEDIDO.every((canal) =>
                              permisosSeleccionados.includes(canal.clave)
                            )}
                            onChange={toggleTodosLosCanales}
                            className="size-4.5 rounded border-gray-300 text-brand-500 focus:ring-brand-400"
                          />
                          <span className="text-xs font-bold text-gray-800 dark:text-white">
                            Todos los canales
                          </span>
                        </label>
                        <div className="mt-2.5 space-y-2.5 pl-7">
                          {CANALES_PEDIDO.map((canal) => (
                            <label key={canal.clave} className="flex cursor-pointer items-center gap-3">
                              <input
                                type="checkbox"
                                checked={permisosSeleccionados.includes(canal.clave)}
                                onChange={() => toggleCanal(canal.clave)}
                                className="size-4.5 rounded border-gray-300 text-brand-500 focus:ring-brand-400"
                              />
                              <span className="text-xs font-medium text-gray-700 dark:text-gray-200">
                                {canal.label}
                              </span>
                            </label>
                          ))}
                        </div>
                      </div>
                    </div>
                  )}
                  {rol === "PERSONALIZADO" && (
                    <div className="space-y-3">
                      <div className="rounded-xl border border-amber-200 bg-amber-50 p-3 text-xs text-amber-800 dark:border-amber-900 dark:bg-amber-950/20 dark:text-amber-300">
                        Solo tendrá acceso a los permisos seleccionados. No puede modificar ni eliminar cuentas Administrador.
                      </div>
                      {GRUPOS_PERMISOS_CONFIGURABLES.map((grupo) => (
                        <section
                          key={grupo.titulo}
                          className="rounded-xl border border-gray-100 bg-gray-50/70 p-4 dark:border-gray-800 dark:bg-gray-800/40"
                        >
                          <h4 className="text-xs font-bold uppercase tracking-wider text-gray-700 dark:text-gray-300">
                            {grupo.titulo}
                          </h4>
                          <div className="mt-3 space-y-2.5">
                            {grupo.permisos.map((permiso) => (
                              <label key={permiso.clave} className="flex cursor-pointer items-center gap-3">
                                <input
                                  type="checkbox"
                                  checked={permisosSeleccionados.includes(permiso.clave)}
                                  onChange={() => togglePermiso(permiso.clave)}
                                  className="size-4.5 rounded border-gray-300 text-brand-500 focus:ring-brand-400"
                                />
                                <span className="text-xs font-medium text-gray-700 dark:text-gray-200">
                                  {permiso.label}
                                </span>
                              </label>
                            ))}
                          </div>
                        </section>
                      ))}
                    </div>
                  )}
                </>
              )}
            </div>

            {/* Footer Fijo */}
            <div className="flex items-center justify-end gap-3 border-t border-gray-100 bg-white px-6 py-4 dark:border-gray-800 dark:bg-gray-900">
              <button
                type="button"
                onClick={() => setDrawerAbierto(false)}
                className="rounded-xl border border-gray-200 px-4 py-2.5 text-sm font-medium text-gray-600 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-300"
              >
                Cancelar
              </button>
              <button
                type="submit"
                disabled={guardando}
                className="rounded-xl bg-brand-500 px-6 py-2.5 text-sm font-bold text-white shadow-sm transition hover:bg-brand-600 disabled:opacity-50"
              >
                {guardando ? "Guardando..." : usuarioEnEdicion ? "Actualizar Cambios" : "Crear Usuario"}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}