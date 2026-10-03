// src/components/UserProfile/DangerZone.tsx
import { useAuth } from "@/context/AuthContext";

export default function DangerZone() {
  const { logout } = useAuth();

  return (
    <div className="rounded-2xl border border-gray-200 bg-white p-5 lg:p-6 dark:border-gray-800 dark:bg-white/3">
      <div>
        <div className="flex flex-col justify-between gap-4 py-2 sm:flex-row sm:items-center">
          <div>
            <span className="block mb-0.5 font-semibold text-base text-gray-800 dark:text-white/90">
              Cerrar Sesión
            </span>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              Finaliza tu sesión activa de trabajo de forma segura.
            </p>
          </div>
          <div>
            <button
              type="button"
              onClick={logout}
              className="flex h-10 items-center justify-center gap-2 rounded-lg border border-red-200 bg-red-50/50 px-4 text-sm font-bold text-red-600 hover:bg-red-100 dark:border-red-900/30 dark:bg-red-950/20 dark:text-red-400"
            >
              Cerrar Sesión
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}