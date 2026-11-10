// src/jobs/pedidosSinRespuesta.js
// Marca los pedidos del cliente que llevan demasiado tiempo sin respuesta
// para que la app le muestre una disculpa y el admin vea el badge "Sin responder".
const prisma = require("../config/prisma");
const { emitPedidoActualizado } = require("../sockets");

const ESPERA_MIN = Number(process.env.PEDIDO_ESPERA_MIN || 10);
const CADA_MS = 60_000;

async function revisar() {
  const limite = new Date(Date.now() - ESPERA_MIN * 60_000);
  const pendientes = await prisma.pedido.findMany({
    where: {
      estado: "PENDIENTE_PAGO",
      atendidoPorId: null, // solo pedidos hechos por el cliente desde su app
      disculpaEnviadaEn: null,
      createdAt: { lt: limite },
    },
    select: { id: true },
    take: 50,
  });

  for (const { id } of pendientes) {
    // updateMany con condición: si otro proceso ya lo tocó, no se duplica el aviso
    const marcado = await prisma.pedido.updateMany({
      where: { id, estado: "PENDIENTE_PAGO", disculpaEnviadaEn: null },
      data: { disculpaEnviadaEn: new Date() },
    });
    if (marcado.count === 0) continue;

    const pedido = await prisma.pedido.findUnique({
      where: { id },
      include: { items: true, pago: true },
    });
    emitPedidoActualizado(pedido);
  }
}

function iniciar() {
  const correr = () => revisar().catch((err) => console.error("[sin-respuesta]", err.message));
  setInterval(correr, CADA_MS);
  correr();
}

module.exports = { iniciar };