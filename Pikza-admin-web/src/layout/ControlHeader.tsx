// src/layout/ControlHeader.tsx
import { Link } from "react-router";
import { ThemeToggleButton } from "@/components/common/ThemeToggleButton";
import { useAuth } from "@/context/AuthContext";
import { useSidebar } from "@/context/SidebarContext";
import { CloseIcon, MenuIcon } from "@/icons";

export default function ControlHeader() {
  const { usuario, logout } = useAuth();
  const { isMobileOpen, toggleSidebar, toggleMobileSidebar } = useSidebar();

  const rolTexto =
    usuario?.rol === "ADMIN"
      ? "Administrador"
      : usuario?.rol === "MOZO"
      ? "Mozo de Salón"
      : usuario?.rol === "REPARTIDOR"
      ? "Repartidor"
      : usuario?.rol === "PERSONALIZADO"
      ? "Configurable"
      : "Cliente";

  function alternarSidebar() {
    if (window.innerWidth >= 1280) toggleSidebar();
    else toggleMobileSidebar();
  }

  return (
    <header className="sticky top-0 z-40 flex h-16 w-full items-center justify-between border-b border-gray-200 bg-white/95 px-4 backdrop-blur md:px-6 dark:border-gray-800 dark:bg-gray-900/95">
      <div className="flex min-w-0 items-center gap-3">
        <button
          type="button"
          aria-label={isMobileOpen ? "Cerrar menú" : "Abrir menú"}
          aria-expanded={isMobileOpen}
          onClick={alternarSidebar}
          className="flex size-10 shrink-0 items-center justify-center rounded-lg border border-gray-200 text-gray-600 hover:bg-gray-50 xl:border-transparent dark:border-gray-700 dark:text-gray-300 dark:hover:bg-white/5"
        >
          {isMobileOpen ? <CloseIcon className="size-5" /> : <MenuIcon className="size-5" />}
        </button>
        <div className="min-w-0">
          <p className="truncate text-sm font-semibold text-gray-800 dark:text-white/90">
            Mamma Pizza
          </p>
          <p className="truncate text-xs text-gray-500 dark:text-gray-400">{rolTexto}</p>
        </div>
      </div>

      <div className="flex shrink-0 items-center gap-2 sm:gap-4">
        <ThemeToggleButton />

        {/* Clic en tu nombre te lleva directo a la página de tu perfil */}
        <Link
          to="/perfil"
          className="hidden min-w-0 rounded-xl px-3 py-1.5 text-right transition hover:bg-gray-100 sm:block dark:hover:bg-gray-800"
          title="Ver y editar mi perfil"
        >
          <p className="max-w-40 truncate text-sm font-bold text-gray-900 dark:text-white">
            {usuario?.nombre}
          </p>
          <p className="text-xs font-semibold text-brand-500">{rolTexto}</p>
        </Link>

        <button
          type="button"
          onClick={logout}
          className="rounded-lg border border-gray-200 px-3 py-2 text-sm font-medium text-gray-600 transition-colors hover:bg-gray-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-white/5"
        >
          Salir
        </button>
      </div>
    </header>
  );
}