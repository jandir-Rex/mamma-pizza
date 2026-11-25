const admin = require("firebase-admin");
const prisma = require("../../config/prisma");

const ROLES_POR_APP = {
  cliente: "CLIENTE",
  repartidor: "REPARTIDOR",
};
const MAX_FIDS_POR_ENVIO = 500;

let firebaseMessaging = null;
let inicializacionIntentada = false;

function obtenerFirebaseMessaging() {
  if (inicializacionIntentada) return firebaseMessaging;
  inicializacionIntentada = true;

  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!serviceAccountJson) {
    console.warn(
      "[notificaciones] FIREBASE_SERVICE_ACCOUNT_JSON no configurada; los avisos push están deshabilitados."
    );
    return null;
  }

  try {
    const serviceAccount = JSON.parse(serviceAccountJson);
    const appExistente = admin.apps.find((app) => app.name === "mamma-pizza-notificaciones");
    const firebaseApp =
      appExistente ||
      admin.initializeApp(
        { credential: admin.credential.cert(serviceAccount) },
        "mamma-pizza-notificaciones"
      );
    firebaseMessaging = admin.messaging(firebaseApp);
    console.info("[notificaciones] Firebase Cloud Messaging inicializado.");
    return firebaseMessaging;
  } catch (error) {
    console.error("[notificaciones] No se pudo inicializar Firebase Admin:", error.message);
    return null;
  }
}

async function registrarInstalacion({ usuarioId, rol, app, fid }) {
  if (ROLES_POR_APP[app] !== rol) {
    const error = new Error("La aplicación no corresponde al rol de esta cuenta");
    error.status = 403;
    throw error;
  }

  return prisma.instalacionNotificacion.upsert({
    where: { fid },
    create: { usuarioId, app, fid },
    update: { usuarioId, app },
  });
}

async function eliminarInstalacion({ usuarioId, fid }) {
  return prisma.instalacionNotificacion.deleteMany({ where: { usuarioId, fid } });
}

async function enviarAUsuario({ usuarioId, app, titulo, cuerpo, data }) {
  const messaging = obtenerFirebaseMessaging();
  if (!messaging) return;

  try {
    const registros = await prisma.instalacionNotificacion.findMany({
      where: { usuarioId, app },
      select: { fid: true },
    });
    const fids = registros.map(({ fid }) => fid);

    for (let inicio = 0; inicio < fids.length; inicio += MAX_FIDS_POR_ENVIO) {
      const lote = fids.slice(inicio, inicio + MAX_FIDS_POR_ENVIO);
      const respuesta = await messaging.sendEachForMulticast({
        fids: lote,
        notification: { title: titulo, body: cuerpo },
        data: Object.fromEntries(
          Object.entries(data).map(([clave, valor]) => [clave, String(valor)])
        ),
        android: {
          priority: "high",
          notification: { channelId: "mamma_pizza_orders", sound: "default" },
        },
      });

      const fidsInvalidos = [];
      respuesta.responses.forEach((resultado, indice) => {
        if (resultado.success) return;
        const codigo = resultado.error?.code || "unknown";
        if (
          codigo === "messaging/installation-id-not-registered" ||
          codigo === "messaging/registration-token-not-registered"
        ) {
          fidsInvalidos.push(lote[indice]);
        } else {
          console.error(
            `[notificaciones] Falló un envío a ${app} (usuario ${usuarioId}): ${codigo}`
          );
        }
      });

      if (fidsInvalidos.length > 0) {
        await prisma.instalacionNotificacion.deleteMany({
          where: { usuarioId, app, fid: { in: fidsInvalidos } },
        });
      }
    }
  } catch (error) {
    console.error(
      `[notificaciones] No se pudo enviar a ${app} (usuario ${usuarioId}):`,
      error.message
    );
  }
}

async function notificarRepartidorAsignado(pedidoId, repartidorId) {
  try {
    const repartidor = await prisma.repartidor.findUnique({
      where: { id: repartidorId },
      select: { usuarioId: true },
    });
    if (!repartidor) {
      console.error(`[notificaciones] No se encontró el repartidor ${repartidorId} del pedido ${pedidoId}.`);
      return;
    }

    await enviarAUsuario({
      usuarioId: repartidor.usuarioId,
      app: "repartidor",
      titulo: "Nuevo pedido asignado",
      cuerpo: "Tienes un pedido nuevo. Abre la app para ver los detalles.",
      data: { tipo: "asignacion", pedidoId },
    });
  } catch (error) {
    console.error(`[notificaciones] No se pudo notificar la asignación del pedido ${pedidoId}:`, error.message);
  }
}

async function notificarClienteEstado(pedido) {
  const mensajes = {
    CONFIRMADO: "Tu pedido fue confirmado.",
    EN_PREPARACION: "Tu pedido ya está en preparación.",
    EN_CAMINO: "Tu pedido está en camino.",
    ENTREGADO: "Tu pedido fue entregado.",
    CANCELADO: "Tu pedido fue cancelado.",
  };
  const cuerpo = mensajes[pedido?.estado];
  if (!pedido?.clienteId || !cuerpo) return;

  await enviarAUsuario({
    usuarioId: pedido.clienteId,
    app: "cliente",
    titulo: "Actualización de tu pedido",
    cuerpo,
    data: { tipo: "estado_pedido", pedidoId: pedido.id, estado: pedido.estado },
  });
}

obtenerFirebaseMessaging();

module.exports = {
  registrarInstalacion,
  eliminarInstalacion,
  notificarRepartidorAsignado,
  notificarClienteEstado,
};
