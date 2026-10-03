// src/components/UserProfile/UserMetaCard.tsx
import { useEffect, useState } from "react";
import { useAuth } from "@/context/AuthContext";
import { apiRequest } from "@/services/api";
import { PencilIcon } from "@/icons";

type PerfilActualizado = {
  telefono: string | null;
};

export default function UserMetaCard() {
  const { usuario } = useAuth();
  const [drawerAbierto, setDrawerAbierto] = useState(false);

  const [nombre, setNombre] = useState(usuario?.nombre || "");
  const [telefono, setTelefono] = useState("");
  const [guardando, setGuardando] = useState(false);
  const [mensaje, setMensaje] = useState("");
  const [error, setError] = useState("");

  useEffect(() => {
    let activo = true;

    apiRequest<PerfilActualizado>("/auth/sesion")
      .then((perfil) => {
        if (activo) setTelefono(perfil.telefono ?? "");
      })
      .catch((err: unknown) => {
        if (activo) {
          setError(err instanceof Error ? err.message : "No se pudo cargar el teléfono");
        }
      });

    return () => {
      activo = false;
    };
  }, []);

  const rolTexto =
    usuario?.rol === "ADMIN"
      ? "Administrador General"
      : usuario?.rol === "MOZO"
      ? "Mozo de Salón"
      : usuario?.rol === "REPARTIDOR"
      ? "Repartidor"
      : usuario?.rol === "PERSONALIZADO"
      ? "Configurable"
      : "Cliente";

  // Iniciales para el avatar
  const iniciales = (usuario?.nombre || "U")
    .split(" ")
    .map((n) => n[0])
    .slice(0, 2)
    .join("")
    .toUpperCase();

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setGuardando(true);
    setError("");
    setMensaje("");

    try {
      const payload: Record<string, string> = {
        nombre: nombre.trim(),
        telefono: telefono.trim(),
      };

      const actualizado = await apiRequest<PerfilActualizado>("/auth/perfil", {
        method: "PATCH",
        body: JSON.stringify(payload),
      });
      setTelefono(actualizado.telefono ?? "");

      // Actualizar localStorage
      const stored = JSON.parse(localStorage.getItem("usuario") ?? "{}");
      stored.nombre = nombre.trim();
      stored.telefono = actualizado.telefono;
      localStorage.setItem("usuario", JSON.stringify(stored));

      setMensaje("Datos actualizados correctamente.");
      setTimeout(() => {
        setDrawerAbierto(false);
        window.location.reload();
      }, 800);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error al guardar cambios");
    } finally {
      setGuardando(false);
    }
  };

  return (
    <>
      <div className="rounded-2xl border border-gray-200 bg-white p-5 lg:p-6 dark:border-gray-800 dark:bg-white/3">
        <div className="flex flex-col gap-5 sm:flex-row xl:gap-10">
          <div className="flex-1">
            <div className="mb-6 flex flex-col gap-5 sm:flex-row xl:items-center xl:justify-between">
              <div className="flex w-full flex-col items-start gap-6 sm:flex-row sm:items-center">
                <div className="flex size-20 shrink-0 items-center justify-center rounded-full bg-brand-500 text-2xl font-black text-white shadow-sm">
                  {iniciales}
                </div>
                <div className="text-left">
                  <h4 className="mb-1 text-lg font-bold text-gray-800 dark:text-white/90">
                    {usuario?.nombre}
                  </h4>
                  <div className="flex items-center gap-1 sm:gap-3">
                    <p className="text-sm font-semibold text-brand-600 dark:text-brand-400">
                      {rolTexto}
                    </p>
                    <div className="hidden h-3.5 w-px bg-gray-300 sm:block dark:bg-gray-700"></div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                      Mamma Pizza Local
                    </p>
                  </div>
                </div>
              </div>
            </div>

            <div className="relative grid max-w-4xl grid-cols-1 gap-5 sm:grid-cols-2 xl:grid-cols-3 xl:gap-x-11 xl:gap-y-7">
              <div>
                <p className="mb-1 text-xs font-bold uppercase tracking-wider text-gray-400">
                  Nombres y Apellidos
                </p>
                <p className="text-sm font-medium text-gray-800 dark:text-white/90">
                  {usuario?.nombre}
                </p>
              </div>

              <div>
                <p className="mb-1 text-xs font-bold uppercase tracking-wider text-gray-400">
                  Correo Electrónico
                </p>
                <p className="text-sm font-medium text-gray-800 dark:text-white/90">
                  {usuario?.email}
                </p>
              </div>

              <div>
                <p className="mb-1 text-xs font-bold uppercase tracking-wider text-gray-400">
                  Teléfono de Contacto
                </p>
                <p className="text-sm font-medium text-gray-800 dark:text-white/90">
                  {telefono || "No registrado"}
                </p>
              </div>
            </div>
          </div>

          <div>
            <button
              type="button"
              onClick={() => setDrawerAbierto(true)}
              className="flex h-10 w-full items-center justify-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-sm font-medium text-gray-700 shadow-theme-xs hover:bg-gray-50 hover:text-gray-800 lg:inline-flex lg:w-auto dark:border-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:hover:bg-white/3 dark:hover:text-gray-200"
            >
              <PencilIcon className="size-4.5" />
              Editar
            </button>
          </div>
        </div>
      </div>

      <div
        className={`fixed inset-0 z-50 transition-opacity duration-300 ease-in-out ${
          drawerAbierto ? "pointer-events-auto opacity-100" : "pointer-events-none opacity-0"
        }`}
        aria-hidden={!drawerAbierto}
      >
        <button
          type="button"
          aria-label="Cerrar edición del perfil"
          onClick={() => setDrawerAbierto(false)}
          className="fixed inset-0 bg-black/60 backdrop-blur-[2px]"
        />

        <aside
          role="dialog"
          aria-modal="true"
          aria-labelledby="editar-perfil-titulo"
          className={`absolute inset-y-0 right-0 flex h-dvh w-full max-w-md flex-col overflow-y-auto bg-white p-6 shadow-2xl transition-transform duration-300 ease-out dark:bg-gray-900 ${
            drawerAbierto ? "translate-x-0" : "translate-x-full"
          }`}
        >
          <div className="flex items-center justify-between border-b border-gray-100 pb-4 dark:border-gray-800">
            <div>
              <h3 id="editar-perfil-titulo" className="text-base font-bold text-gray-900 dark:text-white">
                Editar Información Personal
              </h3>
              <p className="text-xs text-gray-500">
                Modifica tu nombre visible en las comandas y tu teléfono.
              </p>
            </div>
            <button
              type="button"
              aria-label="Cerrar"
              onClick={() => setDrawerAbierto(false)}
              className="text-gray-400 hover:text-gray-600 dark:hover:text-white"
            >
              <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.8" className="size-5">
                <path strokeLinecap="round" strokeLinejoin="round" d="M6 6l8 8m0-8-8 8" />
              </svg>
            </button>
          </div>

          {error && <div role="alert" className="mt-4 rounded-xl bg-red-50 p-3 text-xs text-red-600">{error}</div>}
          {mensaje && <div role="status" className="mt-4 rounded-xl bg-emerald-50 p-3 text-xs text-emerald-600">{mensaje}</div>}

          <form onSubmit={handleSave} id="form-perfil" className="mt-5 space-y-4">
            <div>
              <label htmlFor="perfil-nombre" className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                Nombres y Apellidos *
              </label>
              <input
                id="perfil-nombre"
                type="text"
                required
                minLength={2}
                value={nombre}
                onChange={(e) => setNombre(e.target.value)}
                placeholder="Tu nombre completo"
                className="mt-1.5 h-10 w-full rounded-xl border border-gray-300 bg-white px-3 text-sm text-gray-900 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
              />
            </div>

            <div>
              <label htmlFor="perfil-telefono" className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                Teléfono de Contacto
              </label>
              <input
                id="perfil-telefono"
                type="tel"
                inputMode="numeric"
                maxLength={9}
                pattern="[0-9]{9}"
                value={telefono}
                onChange={(e) => setTelefono(e.target.value.replace(/\D/g, "").slice(0, 9))}
                placeholder="Ej: 999888777"
                className="mt-1.5 h-10 w-full rounded-xl border border-gray-300 bg-white px-3 text-sm text-gray-900 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
              />
              <p className="mt-1 text-xs text-gray-500">Ingresa 9 dígitos, sin espacios ni guiones.</p>
            </div>

            <div>
              <label htmlFor="perfil-email" className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                Correo Electrónico (No modificable)
              </label>
              <input
                id="perfil-email"
                type="email"
                value={usuario?.email || ""}
                disabled
                className="mt-1.5 h-10 w-full rounded-xl border border-gray-200 bg-gray-50 px-3 text-sm text-gray-400 dark:border-gray-800 dark:bg-gray-800/50"
              />
            </div>
          </form>

          <div className="mt-6 flex justify-end gap-2 border-t border-gray-100 pt-4 dark:border-gray-800">
            <button
              type="button"
              onClick={() => setDrawerAbierto(false)}
              className="rounded-lg border border-gray-300 px-4 py-2 text-xs font-semibold text-gray-600 dark:border-gray-700 dark:text-gray-300"
            >
              Cancelar
            </button>
            <button
              type="submit"
              form="form-perfil"
              disabled={guardando}
              className="rounded-lg bg-brand-500 px-5 py-2 text-xs font-bold text-white hover:bg-brand-600 disabled:opacity-50"
            >
              {guardando ? "Guardando..." : "Guardar Cambios"}
            </button>
          </div>
        </aside>
      </div>
    </>
  );
}