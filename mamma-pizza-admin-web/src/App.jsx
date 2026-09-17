import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider } from "./context/AuthContext";
import RutaProtegida from "./components/RutaProtegida";
import Login from "./pages/Login";
import Pedidos from "./pages/Pedidos";

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route
            path="/pedidos"
            element={
              <RutaProtegida>
                <Pedidos />
              </RutaProtegida>
            }
          />
          <Route path="*" element={<Navigate to="/pedidos" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}