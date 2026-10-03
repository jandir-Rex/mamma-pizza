// src/context/AuthContext.tsx
import { createContext, useContext, useEffect, useState } from "react";
import { apiRequest } from "@/services/api";
import { conectarSocket, desconectarSocket } from "@/services/socket";

export type UsuarioStaff = {
  id: number;
  nombre: string;
  email: string;
  rol: "ADMIN" | "MOZO" | "REPARTIDOR" | "PERSONALIZADO" | "CLIENTE";
  permisos: string[];
};

type AuthContextValue = {
  usuario: UsuarioStaff | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  tienePermiso: (permiso: string) => boolean;
};

const AuthContext = createContext<AuthContextValue | null>(null);

function usuarioGuardado(): UsuarioStaff | null {
  try {
    const value = JSON.parse(localStorage.getItem("usuario") ?? "null");
    if (!value || typeof value !== "object" || !("rol" in value)) return null;
    return value as UsuarioStaff;
  } catch {
    return null;
  }
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [usuario, setUsuario] = useState<UsuarioStaff | null>(() =>
    localStorage.getItem("token") ? usuarioGuardado() : null,
  );

  useEffect(() => {
    if (!localStorage.getItem("token")) return;

    conectarSocket();

    async function sincronizarSesion(reconectarSocket = false) {
      if (!localStorage.getItem("token")) return;
      try {
        const actualizado = await apiRequest<UsuarioStaff>("/auth/sesion");
        if (actualizado.rol === "CLIENTE") {
          localStorage.removeItem("token");
          localStorage.removeItem("usuario");
          setUsuario(null);
          desconectarSocket();
          window.location.href = "/login";
          return;
        }

        const anterior = usuarioGuardado();
        const permisosAnteriores = [...(anterior?.permisos ?? [])].sort().join(",");
        const permisosActuales = [...actualizado.permisos].sort().join(",");
        const cambioAcceso =
          anterior?.rol !== actualizado.rol ||
          permisosAnteriores !== permisosActuales;

        localStorage.setItem("usuario", JSON.stringify(actualizado));
        setUsuario(actualizado);

        if (cambioAcceso || reconectarSocket) {
          desconectarSocket();
          conectarSocket();
        }
      } catch (error) {
        console.error("No se pudo sincronizar el acceso de la sesión", error);
      }
    }

    const refrescar = () => {
      void sincronizarSesion();
    };
    const refrescarPorCambioAutorizacion = () => {
      void sincronizarSesion(true);
    };
    const intervalo = window.setInterval(refrescar, 30_000);
    window.addEventListener("focus", refrescar);
    window.addEventListener("auth:changed", refrescarPorCambioAutorizacion);
    refrescar();

    return () => {
      window.clearInterval(intervalo);
      window.removeEventListener("focus", refrescar);
      window.removeEventListener("auth:changed", refrescarPorCambioAutorizacion);
    };
  }, [usuario?.id]);

  async function login(email: string, password: string) {
    const data = await apiRequest<{
      token: string;
      usuario: UsuarioStaff;
    }>("/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    });

    // Rechazamos clientes normales del panel administrativo
    if (data.usuario.rol === "CLIENTE") {
      throw new Error("No tienes acceso al panel de administración");
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

  // Helper global para verificar permisos
  function tienePermiso(permiso: string): boolean {
    if (!usuario) return false;
    if (usuario.rol === "ADMIN") return true; // Admin puede todo
    return usuario.permisos?.includes(permiso) || false;
  }

  return (
    <AuthContext.Provider value={{ usuario, login, logout, tienePermiso }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error("useAuth debe usarse dentro de AuthProvider");
  return context;
}