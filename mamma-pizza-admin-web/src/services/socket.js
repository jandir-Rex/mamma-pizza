import { io } from "socket.io-client";

let socket = null;

export function conectarSocket() {
  const token = localStorage.getItem("token");
  if (!token) return null;

  socket = io(import.meta.env.VITE_SOCKET_URL, {
    auth: { token },
  });

  return socket;
}

export function obtenerSocket() {
  return socket;
}

export function desconectarSocket() {
  if (socket) {
    socket.disconnect();
    socket = null;
  }
}