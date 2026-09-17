// src/components/RutaProtegida.jsx
import { Navigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext"; // ajusta según cómo exportes el hook

export default function RutaProtegida({ children }) {
    const { user } = useAuth(); // o el nombre que uses en tu contexto

    if (!user) {
        return <Navigate to="/login" replace />;
    }

    return children;
}