import { io, type Socket } from "socket.io-client";
import { API_ORIGIN } from "@/services/api";

let socket: Socket | null = null;

export function conectarSocket() {
  if (socket?.connected) return socket;

  const token = localStorage.getItem("token");
  if (!token) return null;

  socket?.disconnect();
  socket = io(import.meta.env.VITE_SOCKET_URL ?? API_ORIGIN, {
    auth: { token },
  });
  socket.on("auth:changed", () => {
    window.dispatchEvent(new Event("auth:changed"));
    socket?.disconnect();
    socket = null;
  });

  return socket;
}

export function obtenerSocket() {
  return socket;
}

export function desconectarSocket() {
  socket?.disconnect();
  socket = null;
}