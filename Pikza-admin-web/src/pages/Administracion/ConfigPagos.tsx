// src/pages/Administracion/ConfigPagos.tsx
import { useCallback, useEffect, useRef, useState } from "react";
import { API_BASE_URL, apiRequest } from "@/services/api";

type ConfigPago = {
  yapeNumero: string | null;
  yapeTitular: string | null;
  tieneQr: boolean;
  qrVersion: number | null;
  origen: "PANEL" | "ENV" | "SIN_CONFIGURAR";
  actualizadoEn: string | null;
};

const TIPOS_PERMITIDOS = ["image/jpeg", "image/png", "image/webp"];
const MAX_BYTES = 5 * 1024 * 1024;

const ETIQUETA = "mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300";
const INPUT =
  "h-11 w-full rounded-lg border border-gray-300 bg-white px-4 text-sm text-gray-800 outline-none focus:border-brand-500 focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90";

function limpiarNumero(valor: string) {
  return valor.replace(/[\s-]/g, "");
}

function formatearNumero(valor: string | null) {
  if (!valor) return "—";
  const n = limpiarNumero(valor);
  return n.length === 9 ? `${n.slice(0, 3)} ${n.slice(3, 6)} ${n.slice(6)}` : valor;
}

export default function ConfigPagos() {
  const [config, setConfig] = useState<ConfigPago | null>(null);
  const [numero, setNumero] = useState("");
  const [titular, setTitular] = useState("");
  const [archivo, setArchivo] = useState<File | null>(null);
  const [previewLocal, setPreviewLocal] = useState<string | null>(null);
  const [quitarQr, setQuitarQr] = useState(false);

  const [cargando, setCargando] = useState(true);
  const [guardando, setGuardando] = useState(false);
  const [error, setError] = useState("");
  const [exito, setExito] = useState("");
  const inputArchivo = useRef<HTMLInputElement>(null);

  const cargar = useCallback(async () => {
    try {
      const data = await apiRequest<ConfigPago>("/pagos/config");
      setConfig(data);
      setNumero(data.yapeNumero ?? "");
      setTitular(data.yapeTitular ?? "");
      setError("");
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudo cargar la configuración");
    } finally {
      setCargando(false);
    }
  }, []);

  useEffect(() => {
    void cargar();
  }, [cargar]);

  // Libera la vista previa local al cambiarla o al salir de la pantalla
  useEffect(() => {
    return () => {
      if (previewLocal) URL.revokeObjectURL(previewLocal);
    };
  }, [previewLocal]);

  const numeroLimpio = limpiarNumero(numero);
  const numeroValido = /^9\d{8}$/.test(numeroLimpio);

  const qrActual =
    config?.tieneQr && !quitarQr ? `${API_BASE_URL}/pagos/qr?v=${config.qrVersion ?? 0}` : null;
  const qrMostrado = previewLocal ?? qrActual;

  const hayCambios =
    numeroLimpio !== (config?.yapeNumero ?? "") ||
    titular.trim() !== (config?.yapeTitular ?? "") ||
    archivo !== null ||
    quitarQr;

  function elegirArchivo(file: File | undefined) {
    setError("");
    setExito("");
    if (!file) return;
    if (!TIPOS_PERMITIDOS.includes(file.type)) {
      setError("El QR debe ser una imagen JPG, PNG o WEBP");
      return;
    }
    if (file.size > MAX_BYTES) {
      setError("La imagen no puede superar los 5 MB");
      return;
    }
    setArchivo(file);
    setQuitarQr(false);
    setPreviewLocal(URL.createObjectURL(file));
  }

  function descartarArchivo() {
    setArchivo(null);
    setPreviewLocal(null);
    if (inputArchivo.current) inputArchivo.current.value = "";
  }

  async function guardar() {
    setError("");
    setExito("");
    if (!numeroValido) {
      setError("El número de Yape debe tener 9 dígitos y empezar con 9");
      return;
    }

    setGuardando(true);
    try {
      await apiRequest("/pagos/config", {
        method: "PUT",
        body: JSON.stringify({ yapeNumero: numeroLimpio, yapeTitular: titular.trim() }),
      });

      if (archivo) {
        const formulario = new FormData();
        formulario.append("imagen", archivo);
        await apiRequest("/pagos/qr", { method: "POST", body: formulario });
      } else if (quitarQr && config?.tieneQr) {
        await apiRequest("/pagos/qr", { method: "DELETE" });
      }

      descartarArchivo();
      setQuitarQr(false);
      await cargar();
      setExito("Listo. Los clientes verán estos datos en su próximo pedido.");
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudo guardar");
    } finally {
      setGuardando(false);
    }
  }

  if (cargando) {
    return <p className="p-6 text-sm text-gray-500 dark:text-gray-400">Cargando configuración de pagos...</p>;
  }

  return (
    <div className="mx-auto max-w-4xl space-y-6">
      <header>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Pagos</h1>
        <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
          Número de Yape y QR a los que pagan tus clientes desde la app. Puedes cambiarlos cuando quieras.
        </p>
      </header>

      {config?.origen === "ENV" && (
        <p className="rounded-lg bg-amber-50 p-3 text-sm text-amber-700 dark:bg-amber-500/10 dark:text-amber-400">
          Ahora se está usando el número guardado en el servidor (archivo <code>.env</code>). Guarda uno aquí para
          manejarlo desde el panel.
        </p>
      )}
      {config?.origen === "SIN_CONFIGURAR" && (
        <p className="rounded-lg bg-red-50 p-3 text-sm text-red-600 dark:bg-red-500/10 dark:text-red-400">
          Aún no hay un número de Yape configurado: los clientes no sabrán a dónde pagar.
        </p>
      )}

      <div className="grid gap-6 lg:grid-cols-[1fr_320px]">
        {/* ------- Formulario ------- */}
        <section className="space-y-5 rounded-xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900">
          <div>
            <label htmlFor="yape-numero" className={ETIQUETA}>
              Número de Yape
            </label>
            <input
              id="yape-numero"
              type="tel"
              inputMode="numeric"
              autoComplete="off"
              value={numero}
              onChange={(e) => {
                setNumero(e.target.value);
                setExito("");
              }}
              placeholder="987 654 321"
              maxLength={13}
              className={INPUT}
              aria-invalid={numero !== "" && !numeroValido}
            />
            {numero !== "" && !numeroValido && (
              <p className="mt-1 text-xs text-red-600">Deben ser 9 dígitos y empezar con 9.</p>
            )}
          </div>

          <div>
            <label htmlFor="yape-titular" className={ETIQUETA}>
              Nombre del titular <span className="font-normal text-gray-400">(opcional)</span>
            </label>
            <input
              id="yape-titular"
              type="text"
              value={titular}
              onChange={(e) => {
                setTitular(e.target.value);
                setExito("");
              }}
              placeholder="Ej.: Mamma Pizza S.A.C."
              maxLength={80}
              className={INPUT}
            />
            <p className="mt-1 text-xs text-gray-400">
              Así el cliente confirma que está yapeando a la persona correcta.
            </p>
          </div>

          <div>
            <span className={ETIQUETA}>Código QR de Yape</span>
            <div className="flex items-start gap-4">
              <div className="flex size-36 shrink-0 items-center justify-center overflow-hidden rounded-lg border border-dashed border-gray-300 bg-gray-50 dark:border-gray-700 dark:bg-gray-800">
                {qrMostrado ? (
                  <img src={qrMostrado} alt="QR de Yape" className="size-full object-contain" />
                ) : (
                  <span className="px-3 text-center text-xs text-gray-400">Sin QR</span>
                )}
              </div>

              <div className="space-y-2">
                <input
                  ref={inputArchivo}
                  type="file"
                  accept="image/jpeg,image/png,image/webp"
                  className="hidden"
                  onChange={(e) => elegirArchivo(e.target.files?.[0])}
                />
                <button
                  type="button"
                  onClick={() => inputArchivo.current?.click()}
                  className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-200 dark:hover:bg-white/5"
                >
                  {qrMostrado ? "Cambiar imagen" : "Subir imagen"}
                </button>

                {archivo && (
                  <button
                    type="button"
                    onClick={descartarArchivo}
                    className="block text-xs font-semibold text-gray-500 hover:underline"
                  >
                    Descartar la imagen elegida
                  </button>
                )}
                {!archivo && config?.tieneQr && (
                  <button
                    type="button"
                    onClick={() => setQuitarQr((q) => !q)}
                    className="block text-xs font-semibold text-red-600 hover:underline"
                  >
                    {quitarQr ? "Mantener el QR actual" : "Quitar el QR"}
                  </button>
                )}
                <p className="text-xs text-gray-400">JPG, PNG o WEBP · máx. 5 MB.</p>
              </div>
            </div>
          </div>

          {error && (
            <p role="alert" className="rounded-lg bg-red-50 p-3 text-sm text-red-600 dark:bg-red-950/20">
              {error}
            </p>
          )}
          {exito && (
            <p role="status" className="rounded-lg bg-emerald-50 p-3 text-sm text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400">
              {exito}
            </p>
          )}

          <button
            type="button"
            onClick={guardar}
            disabled={guardando || !hayCambios}
            className="h-11 w-full rounded-lg bg-brand-500 text-sm font-bold text-white transition-colors hover:bg-brand-600 disabled:cursor-not-allowed disabled:opacity-50"
          >
            {guardando ? "Guardando..." : "Guardar cambios"}
          </button>
        </section>

        {/* ------- Vista previa para el cliente ------- */}
        <aside className="h-fit rounded-xl border border-purple-200 bg-purple-50/60 p-5 dark:border-purple-500/20 dark:bg-purple-500/5">
          <h2 className="mb-3 text-xs font-bold uppercase tracking-wider text-gray-400">Así lo verá el cliente</h2>
          <div className="rounded-lg bg-white p-4 text-center shadow-sm dark:bg-gray-900">
            <p className="text-xs text-gray-500 dark:text-gray-400">Yapea a</p>
            <p className="mt-1 text-xl font-black tracking-wide text-gray-900 dark:text-white">
              {formatearNumero(numeroValido ? numeroLimpio : numero || null)}
            </p>
            {titular.trim() && (
              <p className="mt-0.5 text-sm font-semibold text-gray-600 dark:text-gray-300">{titular.trim()}</p>
            )}
            {qrMostrado && (
              <img src={qrMostrado} alt="" className="mx-auto mt-4 size-40 object-contain" />
            )}
          </div>
          {config?.actualizadoEn && config.origen === "PANEL" && (
            <p className="mt-3 text-center text-[11px] text-gray-400">
              Última actualización: {new Date(config.actualizadoEn).toLocaleString("es-PE")}
            </p>
          )}
        </aside>
      </div>
    </div>
  );
}