// src/components/UserProfile/Security.tsx
import { useState } from "react";
import { apiRequest } from "@/services/api";
import { useModal } from "@/hooks/useModal";
import Input from "../form/input/InputField";
import Label from "../form/Label";
import Button from "../ui/button/Button";
import { Modal } from "../ui/modal";

export default function Security() {
  const { isOpen, openModal, closeModal } = useModal();
  const [passwordActual, setPasswordActual] = useState("");
  const [passwordNuevo, setPasswordNuevo] = useState("");
  const [passwordConfirm, setPasswordConfirm] = useState("");
  const [guardando, setGuardando] = useState(false);
  const [error, setError] = useState("");
  const [mensaje, setMensaje] = useState("");

  const handleCambiarPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (passwordNuevo !== passwordConfirm) {
      return setError("La nueva contraseña y la confirmación no coinciden.");
    }
    if (passwordNuevo.length < 6) {
      return setError("La nueva contraseña debe tener mínimo 6 caracteres.");
    }

    setGuardando(true);
    setError("");
    setMensaje("");

    try {
      await apiRequest("/auth/perfil", {
        method: "PATCH",
        body: JSON.stringify({ passwordActual, passwordNuevo }),
      });

      setMensaje("Contraseña actualizada con éxito.");
      setPasswordActual("");
      setPasswordNuevo("");
      setPasswordConfirm("");
      setTimeout(() => {
        closeModal();
      }, 1000);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error al cambiar contraseña");
    } finally {
      setGuardando(false);
    }
  };

  return (
    <>
      <div className="rounded-2xl border border-gray-200 bg-white p-5 lg:p-6 dark:border-gray-800 dark:bg-white/3">
        <div>
          <div className="flex flex-col justify-between gap-4 border-b border-gray-200 py-4 first:pt-0 last:border-b-0 last:pb-0 sm:flex-row sm:items-center dark:border-gray-800">
            <div>
              <span className="block mb-1 font-semibold text-base text-gray-800 dark:text-white/90">
                Cambiar Contraseña
              </span>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                Actualiza tu clave de acceso verificando la actual.
              </p>
            </div>
            <div>
              <button
                type="button"
                onClick={openModal}
                className="flex h-10 items-center justify-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-sm font-medium text-gray-700 shadow-theme-xs hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300"
              >
                Cambiar Contraseña
              </button>
            </div>
          </div>
        </div>
      </div>

      <Modal isOpen={isOpen} onClose={closeModal} className="max-w-[480px]">
        <div className="flex min-h-full flex-col p-6 lg:p-8">
          <h4 className="text-xl font-bold text-gray-800 dark:text-white/90">
            Cambiar Contraseña
          </h4>
          <p className="mb-5 text-xs text-gray-500">
            Ingresa tu contraseña actual y define una nueva.
          </p>

          {error && <div className="mb-4 rounded-xl bg-red-50 p-3 text-xs text-red-600">{error}</div>}
          {mensaje && <div className="mb-4 rounded-xl bg-emerald-50 p-3 text-xs text-emerald-600">{mensaje}</div>}

          <form onSubmit={handleCambiarPassword} className="flex flex-1 flex-col">
            <div className="space-y-4">
              <div>
                <Label>Contraseña Actual *</Label>
                <Input
                  type="password"
                  required
                  value={passwordActual}
                  onChange={(e) => setPasswordActual(e.target.value)}
                  placeholder="Tu clave actual"
                />
              </div>

              <div>
                <Label>Nueva Contraseña *</Label>
                <Input
                  type="password"
                  required
                  value={passwordNuevo}
                  onChange={(e) => setPasswordNuevo(e.target.value)}
                  placeholder="Mínimo 6 caracteres"
                />
              </div>

              <div>
                <Label>Confirmar Nueva Contraseña *</Label>
                <Input
                  type="password"
                  required
                  value={passwordConfirm}
                  onChange={(e) => setPasswordConfirm(e.target.value)}
                  placeholder="Repite la nueva clave"
                />
              </div>
            </div>

            <div className="mt-6 flex justify-end gap-3 border-t border-gray-100 pt-4 dark:border-gray-800">
              <button
                type="button"
                onClick={closeModal}
                className="rounded-lg border border-gray-300 px-4 py-3 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300"
              >
                Cancelar
              </button>
              <Button size="sm" disabled={guardando}>
                {guardando ? "Verificando..." : "Actualizar Contraseña"}
              </Button>
            </div>
          </form>
        </div>
      </Modal>
    </>
  );
}