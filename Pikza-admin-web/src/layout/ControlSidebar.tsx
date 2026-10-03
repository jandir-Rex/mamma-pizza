// src/layout/ControlSidebar.tsx
import { useAuth } from "@/context/AuthContext";
import { useSidebar } from "@/context/SidebarContext";
import { BoxCubeIcon, CalenderIcon, ChartAltIcon, GridIcon, ListIcon, UserCircleIcon } from "@/icons";
import { cn } from "@/utils";
import { Link, useLocation } from "react-router";

// Icono SVG para Menú / Carta
function MenuIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      {...props}
    >
      <path d="M12 2a10 10 0 1 0 10 10" />
      <path d="m21.17 8-7.17 4V2" />
      <path d="M3.6 9h16.8" />
      <path d="M3.6 15h16.8" />
    </svg>
  );
}

// Icono SVG para Usuarios / Personal (Estilo TailAdmin)
function UsersIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      {...props}
    >
      <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
      <circle cx="9" cy="7" r="4" />
      <path d="M22 21v-2a4 4 0 0 0-3-3.87" />
      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
    </svg>
  );
}

export default function ControlSidebar() {
  const { usuario, tienePermiso } = useAuth();
  const {
    isExpanded,
    isHovered,
    isMobileOpen,
    setIsHovered,
    setIsMobileOpen,
  } = useSidebar();
  const location = useLocation();
  const expandido = isExpanded || isHovered || isMobileOpen;

  // Construcción dinámica del menú según rol y permisos
  const items = [];

  if (usuario?.rol === "ADMIN") {
    items.push({ nombre: "Resumen", ruta: "/admin", Icono: GridIcon });
  }

  if (usuario?.rol === "REPARTIDOR") {
    items.push({ nombre: "Mis entregas", ruta: "/repartidor", Icono: BoxCubeIcon });
    items.push({ nombre: "Historial", ruta: "/repartidor/historial", Icono: CalenderIcon });
  }
  if (tienePermiso("pedidos:ver")) {
    items.push({
      nombre: "Pedidos",
      ruta: usuario?.rol === "ADMIN" ? "/admin/pedidos" : "/pedidos",
      Icono: ListIcon,
    });
    items.push({ nombre: "Historial", ruta: "/admin/historial", Icono: CalenderIcon });
    items.push({ nombre: "Analíticas y reportes", ruta: "/admin/analiticas", Icono: ChartAltIcon });
  }
  if (tienePermiso("productos:admin")) {
    items.push({ nombre: "Carta & Menú", ruta: "/admin/productos", Icono: MenuIcon });
  }
  if (tienePermiso("usuarios:admin")) {
    items.push({ nombre: "Usuarios", ruta: "/admin/usuarios", Icono: UsersIcon });
  }
  if (usuario) {
    items.push({ nombre: "Mi perfil", ruta: "/perfil", Icono: UserCircleIcon });
  }

  function estaActivo(ruta: string) {
    if (ruta === "/admin/pedidos" || ruta === "/pedidos") {
      return location.pathname === "/admin/pedidos" || location.pathname === "/pedidos";
    }
    return location.pathname === ruta;
  }

  return (
    <aside
      aria-label="Navegación principal"
      onMouseEnter={() => !isExpanded && setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      className={cn(
        "fixed inset-s-0 top-0 z-50 flex h-screen flex-col border-e border-gray-200 bg-white px-4 transition-all duration-200 xl:translate-x-0 dark:border-gray-800 dark:bg-gray-900",
        expandido ? "w-72.5" : "w-22.5",
        isMobileOpen ? "translate-x-0" : "-translate-x-full rtl:translate-x-full",
      )}
    >
      <Link
        to="/"
        aria-label="Mamma Pizza, inicio"
        onClick={() => setIsMobileOpen(false)}
        className={cn(
          "flex h-20 shrink-0 items-center gap-3 border-b border-gray-100 px-1 dark:border-gray-800",
          !expandido && "xl:justify-center",
        )}
      >
        <span className="flex size-9 shrink-0 items-center justify-center rounded-lg bg-brand-500 text-xs font-bold text-white">
          MP
        </span>
        {expandido && (
          <span className="truncate text-sm font-semibold text-gray-800 dark:text-white/90">
            Mamma Pizza
          </span>
        )}
      </Link>

      <nav className="flex-1 py-6">
        {expandido && (
          <p className="mb-3 px-2 text-[11px] font-semibold uppercase text-gray-400">
            Operaciones
          </p>
        )}
        <ul className="space-y-1">
          {items.map(({ nombre, ruta, Icono }) => {
            const activo = estaActivo(ruta);
            return (
              <li key={ruta}>
                <Link
                  to={ruta}
                  aria-current={activo ? "page" : undefined}
                  title={expandido ? undefined : nombre}
                  onClick={() => setIsMobileOpen(false)}
                  className={cn(
                    "flex h-11 items-center gap-3 rounded-lg px-3 text-sm font-medium transition-colors",
                    !expandido && "xl:justify-center xl:px-0",
                    activo
                      ? "bg-brand-50 text-brand-600 dark:bg-brand-500/10 dark:text-brand-400"
                      : "text-gray-600 hover:bg-gray-50 hover:text-gray-900 dark:text-gray-300 dark:hover:bg-white/5 dark:hover:text-white",
                  )}
                >
                  <Icono className={cn("size-5 shrink-0", activo ? "text-brand-500" : "text-gray-400")} />
                  {expandido && <span className="truncate">{nombre}</span>}
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>
    </aside>
  );
}