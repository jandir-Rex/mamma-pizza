// src/components/auth/ProtectedRoute.tsx
import { Navigate, Outlet } from "react-router";
import { useAuth } from "@/context/AuthContext";

type ProtectedRouteProps = {
  roles?: string[];       // Ej: ["ADMIN", "MOZO"] (Opcional)
  permiso?: string;       // Ej: "pedidos:ver" (Opcional y recomendado)
  redirectTo?: string;
};

export default function ProtectedRoute({
  roles,
  permiso,
  redirectTo = "/login",
}: ProtectedRouteProps) {
  const { usuario, tienePermiso } = useAuth();

  // 1. Si no ha iniciado sesión -> Al Login
  if (!usuario) {
    return <Navigate to={redirectTo} replace />;
  }

  // 2. Si es ADMIN -> Pasa siempre a cualquier ruta
  if (usuario.rol === "ADMIN") {
    return <Outlet />;
  }

  // 3. Validación por Rol (si la ruta especificó roles requeridos)
  if (roles && !roles.includes(usuario.rol)) {
    return <Navigate to="/unauthorized" replace />;
  }

  // 4. Validación por Permiso (si la ruta exige un permiso específico)
  if (permiso && !tienePermiso(permiso)) {
    return <Navigate to="/unauthorized" replace />;
  }

  return <Outlet />;
}