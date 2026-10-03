// src/components/header/DrawerMiPerfil.tsx
import { useState } from "react";
import { apiRequest } from "@/services/api";
import { useAuth } from "@/context/AuthContext";

type Props = {
  abierto: boolean;
  onCerrar: () => void;
};

export default function DrawerMiPerfil({ abierto, onCerrar }: Props) {
  const { usuario } = useAuth();
  const [nombre, setNombre] = useState(usuario?.nombre ?? "");
  const [telefono, setTelefono] = useState("");
  const [passwordActual, setPasswordActual] = useState("");
  const [passwordNuevo, setPasswordNuevo] = useState("");
  const [guardando, setGuardando] = useState(false);
  const [mensaje, setMensaje] = useState("");
  const [error, setError] = useState("");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setGuardando(true);
    setError("");
    setMensaje("");

    try {
      const payload: Record<string, string> = {
        nombre: nombre.trim(),
      };
      if (telefono.trim()) payload.telefono = telefono.trim();
      if (passwordNuevo.trim()) {
        payload.passwordActual = passwordActual;
        payload.passwordNuevo = passwordNuevo.trim();
      }

      await apiRequest("/auth/perfil", {
        method: "PATCH",
        body: JSON.stringify(payload),
      });

      // Actualizar localStorage para reflejar el nuevo nombre
      const stored = JSON.parse(localStorage.getItem("usuario") ?? "{}");
      stored.nombre = nombre.trim();
      localStorage.setItem("usuario", JSON.stringify(stored));

      setMensaje("Perfil actualizado correctamente");
      setPasswordActual("");
      setPasswordNuevo("");
      setTimeout(() => {
        setMensaje("");
        onCerrar();
        window.location.reload(); // Refresca cabecera
      }, 1000);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error al actualizar perfil");
    } finally {
      setGuardando(false);
    }
  }

  return (
    <div
      className={`fixed inset-0 z-50 transition-opacity duration-300 ease-in-out ${
        abierto ? "pointer-events-auto opacity-100" : "pointer-events-none opacity-0"
      }`}
    >
      <div onClick={onCerrar} className="fixed inset-0 bg-black/60 backdrop-blur-[2px] transition-opacity" />

      <div
        className={`absolute inset-y-0 right-0 flex w-full max-w-md flex-col bg-white shadow-2xl transition-transform duration-300 ease-out dark:bg-gray-900 ${
          abierto ? "translate-x-0" : "translate-x-full"
        }`}
      >
        <div className="flex items-center justify-between border-b border-gray-100 px-6 py-4.5 dark:border-gray-800">
          <div>
            <h2 className="text-lg font-bold text-gray-900 dark:text-white">Mi Perfil</h2>
            <p className="text-xs text-gray-500">Configuración de cuenta personal</p>
          </div>
          <button type="button" onClick={onCerrar} className="text-gray-400 hover:text-gray-600 dark:hover:text-white">✕</button>
        </div>

        <form onSubmit={handleSubmit} className="flex flex-1 flex-col justify-between overflow-y-auto p-6 space-y-4">
          <div className="space-y-4">
            {error && <div className="rounded-xl bg-red-50 p-3 text-xs text-red-600">{error}</div>}
            {mensaje && <div className="rounded-xl bg-emerald-50 p-3 text-xs text-emerald-600">{mensaje}</div>}

            {/* Credencial Fija */}
            <div className="rounded-xl border border-gray-100 bg-gray-50/70 p-3.5 dark:border-gray-800 dark:bg-gray-800/40">
              <span className="text-xs font-bold uppercase tracking-wider text-gray-400">Rol de Acceso</span>
              <p className="text-sm font-bold text-brand-600 dark:text-brand-400">{usuario?.rol}</p>
              <span className="mt-2 block text-xs font-bold uppercase tracking-wider text-gray-400">Correo Electrónico</span>
              <p className="text-xs font-medium text-gray-600 dark:text-gray-300">{usuario?.email}</p>
            </div>

            <div>
              <label className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                Nombres y Apellidos *
              </label>
              <input
                type="text"
                required
                value={nombre}
                onChange={(e) => setNombre(e.target.value)}
                className="mt-1.5 h-10 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
              />
            </div>

            <div>
              <label className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                Teléfono de Contacto
              </label>
              <input
                type="tel"
                placeholder="Ej: 999888777"
                value={telefono}
                onChange={(e) => setTelefono(e.target.value)}
                className="mt-1.5 h-10 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
              />
            </div>

            {/* Cambio de Contraseña */}
            <div className="border-t border-gray-100 pt-4 dark:border-gray-800">
              <span className="text-xs font-bold uppercase tracking-wider text-gray-700 dark:text-gray-300">
                Cambiar Contraseña (Opcional)
              </span>

              <div className="mt-3 space-y-3">
                <div>
                  <label className="text-[11px] font-semibold text-gray-500">Contraseña Actual</label>
                  <input
                    type="password"
                    placeholder="Tu clave actual"
                    value={passwordActual}
                    onChange={(e) => setPasswordActual(e.target.value)}
                    className="mt-1 h-9 w-full rounded-lg border border-gray-300 bg-white px-3 text-xs text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  />
                </div>

                <div>
                  <label className="text-[11px] font-semibold text-gray-500">Nueva Contraseña</label>
                  <input
                    type="password"
                    placeholder="Mínimo 6 caracteres"
                    value={passwordNuevo}
                    onChange={(e) => setPasswordNuevo(e.target.value)}
                    className="mt-1 h-9 w-full rounded-lg border border-gray-300 bg-white px-3 text-xs text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  />
                </div>
              </div>
            </div>
          </div>

          <div className="flex justify-end gap-2 border-t border-gray-100 pt-4 dark:border-gray-800">
            <button
              type="button"
              onClick={onCerrar}
              className="rounded-lg border px-4 py-2 text-xs font-semibold text-gray-600 dark:border-gray-700 dark:text-gray-300"
            >
              Cerrar
            </button>
            <button
              type="submit"
              disabled={guardando}
              className="rounded-lg bg-brand-500 px-5 py-2 text-xs font-bold text-white hover:bg-brand-600 disabled:opacity-50"
            >
              {guardando ? "Guardando..." : "Actualizar Mis Datos"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}