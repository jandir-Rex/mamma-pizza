import { createContext, useContext, useState, useEffect } from "react";
import api from "../services/api";
import { conectarSocket, desconectarSocket } from "../services/socket";

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [usuario, setUsuario] = useState(null);
  const [cargando, setCargando] = useState(true);

  useEffect(() => {
    const usuarioGuardado = localStorage.getItem("usuario");
    const token = localStorage.getItem("token");
    if (usuarioGuardado && token) {
      setUsuario(JSON.parse(usuarioGuardado));
      conectarSocket();
    }
    setCargando(false);
  }, []);

  async function login(email, password) {
    const { data } = await api.post("/auth/login", { email, password });

    if (data.usuario.rol !== "ADMIN") {
      throw new Error("Esta aplicación es solo para administradores");
    }

    localStorage.setItem("token", data.token);
    localStorage.setItem("usuario", JSON.stringify(data.usuario));
    setUsuario(data.usuario);
    conectarSocket();
  }

  function logout() {
    localStorage.removeItem("token");
    localStorage.removeItem("usuario");
    setUsuario(null);
    desconectarSocket();
  }

  return (
    <AuthContext.Provider value={{ usuario, login, logout, cargando }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}