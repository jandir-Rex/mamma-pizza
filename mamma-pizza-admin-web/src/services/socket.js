import { io } from "socket.io-client";

let socket = null;

export function conectarSocket() {
  // Si ya hay una conexión activa, la reusamos en vez de crear otra
  if (socket && socket.connected) {
    return socket;
  }

  const token = localStorage.getItem("token");
  if (!token) return null;

  // Si existe un socket viejo desconectado, lo limpiamos antes de crear uno nuevo
  if (socket) {
    socket.disconnect();
    socket = null;
  }

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