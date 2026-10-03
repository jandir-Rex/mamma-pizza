import { useState, type FormEvent } from "react";
import { useNavigate } from "react-router";
import { useAuth } from "@/context/AuthContext";

export default function PizzaSignInForm() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [enviando, setEnviando] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    setEnviando(true);

    try {
      await login(email, password);
      const usuario = JSON.parse(localStorage.getItem("usuario") ?? "null");
      navigate(usuario?.rol === "ADMIN" ? "/admin" : "/repartidor", {
        replace: true,
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudo iniciar sesión");
    } finally {
      setEnviando(false);
    }
  }

  return (
    <div className="flex flex-1 flex-col justify-center">
      <div className="mx-auto w-full max-w-md">
        <div className="mb-8">
          <p className="mb-2 text-sm font-medium text-brand-500">Mamma Pizza</p>
          <h1 className="text-title-sm font-semibold text-gray-800 sm:text-title-md dark:text-white/90">
            Acceso al panel
          </h1>
          <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
            Ingresa con tu cuenta de administrador o repartidor.
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-5">
          <label className="block">
            <span className="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300">
              Correo electrónico
            </span>
            <input
              type="email"
              autoComplete="username"
              required
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              className="h-11 w-full rounded-lg border border-gray-300 bg-transparent px-4 text-sm text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:text-white"
            />
          </label>

          <label className="block">
            <span className="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300">
              Contraseña
            </span>
            <input
              type="password"
              autoComplete="current-password"
              required
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              className="h-11 w-full rounded-lg border border-gray-300 bg-transparent px-4 text-sm text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:text-white"
            />
          </label>

          {error && (
            <p role="alert" className="text-sm text-error-500">
              {error}
            </p>
          )}

          <button
            type="submit"
            disabled={enviando}
            className="flex h-11 w-full items-center justify-center rounded-lg bg-brand-500 px-4 text-sm font-medium text-white transition-colors hover:bg-brand-600 disabled:cursor-wait disabled:opacity-60"
          >
            {enviando ? "Ingresando..." : "Ingresar"}
          </button>
        </form>
      </div>
    </div>
  );
}