const { Server } = require("socket.io");
const jwt = require("jsonwebtoken");
const { jwtSecret } = require("../config/env");
const prisma = require("../config/prisma");

let io = null;

function initSockets(server) {
  io = new Server(server, {
    cors: { origin: "*" },
  });

  io.use((socket, next) => {
    const token = socket.handshake.auth?.token;
    if (!token) {
      return next(new Error("Token no proporcionado"));
    }
    try {
      const payload = jwt.verify(token, jwtSecret);
      socket.usuario = payload;
      next();
    } catch (err) {
      next(new Error("Token inválido o expirado"));
    }
  });

  io.on("connection", (socket) => {
    const { id, rol } = socket.usuario;

    if (rol === "ADMIN") {
      socket.join("admin");
    }

    if (rol === "REPARTIDOR") {
      socket.join(`repartidor_${id}`);
    }

    socket.on("pedido:seguir", async (pedidoId) => {
      if (!Number.isInteger(pedidoId) || pedidoId <= 0) return;

      if (rol === "ADMIN") {
        socket.join(`pedido_${pedidoId}`);
        return;
      }

      if (rol === "CLIENTE") {
        const pedido = await prisma.pedido.findUnique({ where: { id: pedidoId } });
        if (pedido && pedido.clienteId === id) {
          socket.join(`pedido_${pedidoId}`);
        }
      }
    });

    socket.on("disconnect", () => {});
  });

  return io;
}

function emitPedidoNuevo(pedido) {
  if (!io) return;
  io.to("admin").emit("pedido:nuevo", pedido);
}

function emitPedidoActualizado(pedido) {
  if (!io) return;
  io.to("admin").emit("pedido:actualizado", pedido);
  io.to(`pedido_${pedido.id}`).emit("pedido:actualizado", pedido);
}

function emitDisponibilidadCambiada(variante) {
  if (!io) return;
  io.emit("producto:disponibilidad", variante);
}

module.exports = {
  initSockets,
  emitPedidoNuevo,
  emitPedidoActualizado,
  emitDisponibilidadCambiada,
};