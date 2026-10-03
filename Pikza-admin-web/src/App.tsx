// src/App.tsx
import { BrowserRouter as Router, Navigate, Route, Routes } from "react-router";
import { ScrollToTop } from "./components/common/ScrollToTop";
import ProtectedRoute from "./components/auth/ProtectedRoute";
import { AuthProvider, useAuth } from "./context/AuthContext";
import AppLayout from "./layout/AppLayout";
import SignIn from "./pages/AuthPages/SignIn";
import DashboardAdmin from "./pages/Administracion/DashboardAdmin";
import AnaliticasReportes from "./pages/Administracion/AnaliticasReportes";
import DeliveryDashboard from "./pages/Administracion/DeliveryDashboard";
import HistorialPedidos from "./pages/Administracion/HistorialPedidos";
import RegistroPedidos from "./pages/Administracion/RegistroPedidos";
import ProductosAdmin from "./pages/Administracion/ProductosAdmin";
import GestionUsuarios from "./pages/Administracion/GestionUsuarios";
import UserProfiles from "./pages/UserProfiles";


// Redirige al inicio correcto según quién entra
function RedireccionInicial() {
  const { usuario, tienePermiso } = useAuth();

  if (!usuario) return <Navigate to="/login" replace />;

  if (usuario.rol === "ADMIN") return <Navigate to="/admin" replace />;
  if (usuario.rol === "REPARTIDOR") return <Navigate to="/repartidor" replace />;
  if (tienePermiso("pedidos:ver")) {
    return <Navigate to="/pedidos" replace />;
  }
  if (tienePermiso("productos:admin")) return <Navigate to="/admin/productos" replace />;
  if (tienePermiso("usuarios:admin")) return <Navigate to="/admin/usuarios" replace />;

  return <Navigate to="/sin-acceso" replace />;
}

export default function App() {
  return (
    <AuthProvider>
      <Router>
        <ScrollToTop />
        <Routes>
          {/* Rutas Públicas */}
          <Route path="/" element={<RedireccionInicial />} />
          <Route path="/login" element={<SignIn />} />
          <Route path="/signin" element={<Navigate to="/login" replace />} />

          {/* Rutas dentro del Layout Principal */}
          <Route element={<AppLayout />}>

            {/* El resumen es exclusivo del administrador. El perfil es personal. */}
            <Route element={<ProtectedRoute roles={["ADMIN"]} />}>
              <Route path="/admin" element={<DashboardAdmin />} />
            </Route>

            <Route element={<ProtectedRoute />}>
              <Route path="/perfil" element={<UserProfiles />} />
            </Route>

            <Route element={<ProtectedRoute permiso="pedidos:ver" />}>
              <Route path="/admin/analiticas" element={<AnaliticasReportes />} />
              <Route path="/admin/historial" element={<HistorialPedidos />} />
            </Route>

            <Route element={<ProtectedRoute roles={["REPARTIDOR"]} />}>
              <Route path="/repartidor/historial" element={<HistorialPedidos />} />
            </Route>

            <Route element={<ProtectedRoute permiso="productos:admin" />}>
              <Route path="/admin/productos" element={<ProductosAdmin />} />
            </Route>

            <Route element={<ProtectedRoute permiso="usuarios:admin" />}>
              <Route path="/admin/usuarios" element={<GestionUsuarios />} />
            </Route>

            {/* El permiso, no un nombre de rol, determina el acceso al módulo. */}
            <Route element={<ProtectedRoute permiso="pedidos:ver" />}>
              <Route path="/admin/pedidos" element={<RegistroPedidos />} />
              <Route path="/pedidos" element={<RegistroPedidos />} />
            </Route>

            <Route element={<ProtectedRoute roles={["ADMIN", "REPARTIDOR"]} />}>
              <Route path="/repartidor" element={<DeliveryDashboard />} />
            </Route>

          </Route>

          <Route path="/sin-acceso" element={
            <div className="flex min-h-screen items-center justify-center p-6 text-center">
              <div>
                <h1 className="text-xl font-bold text-gray-900 dark:text-white">Sin módulos asignados</h1>
                <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
                  Solicita al administrador que te asigne acceso a un módulo.
                </p>
              </div>
            </div>
          } />

          {/* Redirección por defecto para rutas no encontradas */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Router>
    </AuthProvider>
  );
}