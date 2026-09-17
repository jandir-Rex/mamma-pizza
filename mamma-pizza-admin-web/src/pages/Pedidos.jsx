import { useAuth } from "../context/AuthContext";

export default function Pedidos() {
  const { usuario, logout } = useAuth();

  return (
    <div className="p-6">
      <h1 className="text-xl font-bold text-primary">
        Bienvenido, {usuario?.nombre}
      </h1>
      <p className="text-gray-500">Acá va el tablero de pedidos (siguiente paso)</p>
      <button onClick={logout} className="mt-4 text-sm text-danger underline">
        Cerrar sesión
      </button>
    </div>
  );
}