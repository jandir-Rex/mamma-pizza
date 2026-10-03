// src/components/UserProfile/UserAddressCard.tsx
import { useEffect, useState } from "react";
import { apiRequest } from "@/services/api";
import { PencilIcon } from "@/icons";

type DatosDomicilio = {
  dni: string | null;
  direccion: string | null;
  ciudad: string | null;
};

function CloseIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.8" {...props}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M6 6l8 8m0-8-8 8" />
    </svg>
  );
}

export default function UserAddressCard() {
  const [drawerAbierto, setDrawerAbierto] = useState(false);
  const [dni, setDni] = useState("");
  const [direccion, setDireccion] = useState("");
  const [ciudad, setCiudad] = useState("");
  const [cargandoDatos, setCargandoDatos] = useState(true);
  const [guardando, setGuardando] = useState(false);
  const [mensaje, setMensaje] = useState("");
  const [error, setError] = useState("");

  useEffect(() => {
    let activo = true;

    apiRequest<DatosDomicilio>("/auth/sesion")
      .then((datos) => {
        if (!activo) return;
        setDni(datos.dni ?? "");
        setDireccion(datos.direccion ?? "");
        setCiudad(datos.ciudad ?? "");
      })
      .catch((err: unknown) => {
        if (activo) {
          setError(err instanceof Error ? err.message : "No se pudieron cargar tus datos");
        }
      })
      .finally(() => {
        if (activo) setCargandoDatos(false);
      });

    return () => {
      activo = false;
    };
  }, []);

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setGuardando(true);
    setError("");
    setMensaje("");

    try {
      const actualizados = await apiRequest<DatosDomicilio>("/auth/perfil", {
        method: "PATCH",
        body: JSON.stringify({
          dni: dni.trim(),
          direccion: direccion.trim(),
          ciudad: ciudad.trim(),
        }),
      });

      setDni(actualizados.dni ?? "");
      setDireccion(actualizados.direccion ?? "");
      setCiudad(actualizados.ciudad ?? "");
      setMensaje("Datos guardados correctamente.");
      setTimeout(() => {
        setDrawerAbierto(false);
      }, 800);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error al guardar información");
    } finally {
      setGuardando(false);
    }
  };

  return (
    <>
      <div className="rounded-2xl border border-gray-200 bg-white p-5 lg:p-6 dark:border-gray-800 dark:bg-white/3">
        <div className="flex flex-col gap-6 sm:flex-row lg:items-start lg:justify-between">
          <div className="flex-1">
            <h4 className="text-lg font-bold text-gray-800 lg:mb-6 dark:text-white/90">
              Datos de Domicilio & Referencia Personal
            </h4>

            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 lg:gap-7">
              <div>
                <p className="mb-1 text-xs font-bold uppercase tracking-wider text-gray-400">
                  DNI / Documento de Identidad
                </p>
                <p className="text-sm font-semibold text-gray-800 dark:text-white/90">
                  {dni || (cargandoDatos ? "Cargando..." : "No registrado (opcional)")}
                </p>
              </div>

              <div>
                <p className="mb-1 text-xs font-bold uppercase tracking-wider text-gray-400">
                  Dirección de Residencia
                </p>
                <p className="text-sm font-semibold text-gray-800 dark:text-white/90">
                  {direccion || (cargandoDatos ? "Cargando..." : "No registrada (opcional)")}
                </p>
              </div>

              <div>
                <p className="mb-1 text-xs font-bold uppercase tracking-wider text-gray-400">
                  Ciudad
                </p>
                <p className="text-sm font-semibold text-gray-800 dark:text-white/90">
                  {ciudad || (cargandoDatos ? "Cargando..." : "No configurada")}
                </p>
              </div>
            </div>
          </div>

          <div>
            <button
              type="button"
              onClick={() => setDrawerAbierto(true)}
              disabled={cargandoDatos}
              className="flex h-10 w-full items-center justify-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-sm font-medium text-gray-700 shadow-theme-xs hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:hover:bg-white/3"
            >
              <PencilIcon className="size-4.5" />
              {cargandoDatos ? "Cargando..." : "Editar"}
            </button>
          </div>
        </div>
      </div>

      {/* DRAWER DERECHO: EDITAR DOMICILIO (Reemplaza el modal flotante) */}
      <div
        className={`fixed inset-0 z-50 transition-opacity duration-300 ease-in-out ${
          drawerAbierto ? "pointer-events-auto opacity-100" : "pointer-events-none opacity-0"
        }`}
      >
        <button
          type="button"
          aria-label="Cerrar edición del domicilio"
          onClick={() => setDrawerAbierto(false)}
          className="fixed inset-0 bg-black/60 backdrop-blur-[2px] transition-opacity"
        />

        <div
          className={`absolute inset-y-0 right-0 flex h-dvh w-full max-w-md flex-col overflow-y-auto bg-white p-6 shadow-2xl transition-transform duration-300 ease-out dark:bg-gray-900 ${
            drawerAbierto ? "translate-x-0" : "translate-x-full"
          }`}
        >
          <div>
            <div className="flex items-center justify-between border-b border-gray-100 pb-4 dark:border-gray-800">
              <div>
                <h3 className="text-base font-bold text-gray-900 dark:text-white">
                  Actualizar Domicilio & Referencia
                </h3>
                <p className="text-xs text-gray-500">Datos opcionales para control y prevención interna</p>
              </div>
              <button
                type="button"
                onClick={() => setDrawerAbierto(false)}
                className="text-gray-400 hover:text-gray-600 dark:hover:text-white"
              >
                <CloseIcon className="size-5" />
              </button>
            </div>

            {error && <div className="mt-4 rounded-xl bg-red-50 p-3 text-xs text-red-600">{error}</div>}
            {mensaje && <div className="mt-4 rounded-xl bg-emerald-50 p-3 text-xs text-emerald-600">{mensaje}</div>}

            <form onSubmit={handleSave} id="form-domicilio" className="mt-5 space-y-4">
              <div>
                <label className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                  DNI (Documento de Identidad)
                </label>
                <input
                  type="text"
                  maxLength={20}
                  placeholder="Ej: 72345678"
                  value={dni}
                  onChange={(e) => setDni(e.target.value.replace(/\D/g, ""))}
                  className="mt-1.5 h-10 w-full rounded-xl border border-gray-300 bg-white px-3 text-sm text-gray-900 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                />
              </div>

              <div>
                <label className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                  Dirección de Domicilio
                </label>
                <input
                  type="text"
                  placeholder="Ej: Av. Elmer Faucett 1234, Dpto 301"
                  value={direccion}
                  onChange={(e) => setDireccion(e.target.value)}
                  maxLength={250}
                  className="mt-1.5 h-10 w-full rounded-xl border border-gray-300 bg-white px-3 text-sm text-gray-900 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                />
              </div>

              <div>
                <label className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                  Ciudad
                </label>
                <input
                  type="text"
                  placeholder="Ej: Lima"
                  value={ciudad}
                  onChange={(e) => setCiudad(e.target.value)}
                  maxLength={100}
                  className="mt-1.5 h-10 w-full rounded-xl border border-gray-300 bg-white px-3 text-sm text-gray-900 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                />
              </div>
            </form>
          </div>

          <div className="mt-6 flex justify-end gap-2 border-t border-gray-100 pt-4 dark:border-gray-800">
            <button
              type="button"
              onClick={() => setDrawerAbierto(false)}
              className="rounded-lg border px-4 py-2 text-xs font-semibold text-gray-600 dark:border-gray-700 dark:text-gray-300"
            >
              Cancelar
            </button>
            <button
              type="submit"
              form="form-domicilio"
              disabled={guardando}
              className="rounded-lg bg-brand-500 px-5 py-2 text-xs font-bold text-white hover:bg-brand-600 disabled:opacity-50"
            >
              {guardando ? "Guardando..." : "Guardar Cambios"}
            </button>
          </div>
        </div>
      </div>
    </>
  );
}