import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [cargando, setCargando] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  async function manejarSubmit(e) {
    e.preventDefault();
    setError("");
    setCargando(true);
    try {
      await login(email, password);
      navigate("/pedidos");
    } catch (err) {
      setError(err.response?.data?.error || err.message || "Error al iniciar sesión");
    } finally {
      setCargando(false);
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-bg">
      <form
        onSubmit={manejarSubmit}
        className="bg-white rounded-xl shadow-md p-8 w-full max-w-sm"
      >
        <h1 className="text-2xl font-bold text-primary text-center mb-1">
          Mamma Pizza
        </h1>
        <p className="text-sm text-center text-gray-500 mb-6">
          Panel de Administración
        </p>

        {error && (
          <div className="bg-red-50 text-danger text-sm rounded-md p-2 mb-4">
            {error}
          </div>
        )}

        <label className="block text-sm font-medium mb-1">Email</label>
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
          className="w-full border rounded-md px-3 py-2 mb-4 outline-none focus:border-primary"
        />

        <label className="block text-sm font-medium mb-1">Contraseña</label>
        <input
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
          className="w-full border rounded-md px-3 py-2 mb-6 outline-none focus:border-primary"
        />

        <button
          type="submit"
          disabled={cargando}
          className="w-full bg-primary text-white rounded-md py-2 font-medium disabled:opacity-60"
        >
          {cargando ? "Ingresando..." : "Ingresar"}
        </button>
      </form>
    </div>
  );
}