// src/modules/pedidos/pedidos.service.js
const prisma = require("../../config/prisma");
const { emitPedidoNuevo, emitPedidoActualizado } = require("../../sockets");

const PERMISOS_POR_CANAL = {
  SALON: "pedidos:canal:SALON",
  PARA_LLEVAR: "pedidos:canal:PARA_LLEVAR",
  DELIVERY: "pedidos:canal:DELIVERY",
};

function obtenerCanalOperativo(pedido) {
  if (pedido.canal === "DELIVERY") return "DELIVERY";
  return pedido.mesaId ? "SALON" : "PARA_LLEVAR";
}

function validarAccesoCanal(solicitante, pedido, permisoBase) {
  if (!["MOZO", "PERSONALIZADO"].includes(solicitante?.rol)) return;
  const permisos = solicitante.permisos || [];
  if (!permisos.includes(permisoBase) || !permisos.includes(PERMISOS_POR_CANAL[obtenerCanalOperativo(pedido)])) {
    const error = new Error("No tienes permiso para gestionar pedidos de este canal");
    error.status = 403;
    throw error;
  }
}

function generarCodigo() {
  return `PZ-${Date.now().toString(36).toUpperCase()}`;
}

const TRANSICIONES_VALIDAS = {
  PENDIENTE_PAGO: ["CONFIRMADO", "CANCELADO"],
  CONFIRMADO: ["EN_PREPARACION", "CANCELADO"],
  EN_PREPARACION: ["EN_CAMINO", "ENTREGADO", "CANCELADO"],
  EN_CAMINO: ["ENTREGADO", "CANCELADO"],
  ENTREGADO: [],
  CANCELADO: [],
};

async function crearPedido(clienteId, rolSolicitante, datos, solicitante) {
  const { canal, direccionId, mesaId, metodoPago, items, clienteNombre } = datos;

  if (["MOZO", "PERSONALIZADO"].includes(rolSolicitante)) {
    const canalOperativo = canal === "DELIVERY" ? "DELIVERY" : mesaId ? "SALON" : "PARA_LLEVAR";
    validarAccesoCanal(solicitante, { canal, mesaId }, "pedidos:crear");
    if (canalOperativo === "DELIVERY") {
      const error = new Error("El personal de salón no puede registrar pedidos de delivery");
      error.status = 403;
      throw error;
    }
  }

  if (canal === "DELIVERY") {
    const direccion = await prisma.direccion.findUnique({ where: { id: direccionId } });
    if (!direccion) {
      const error = new Error("La dirección indicada no existe");
      error.status = 400;
      throw error;
    }
    if (direccion.usuarioId !== clienteId) {
      const error = new Error("Esa dirección no pertenece a tu cuenta");
      error.status = 403;
      throw error;
    }
  }

  if (canal === "SALON" && mesaId) {
    const mesa = await prisma.mesa.findUnique({ where: { id: mesaId } });
    if (!mesa) {
      const error = new Error("La mesa indicada no existe");
      error.status = 400;
      throw error;
    }

    // Solo bloquea si hay un pedido activo de HOY
    const hoy = new Date();
    hoy.setHours(0, 0, 0, 0);

    const pedidoActivo = await prisma.pedido.findFirst({
      where: {
        mesaId,
        estado: { notIn: ["ENTREGADO", "CANCELADO"] },
        createdAt: { gte: hoy }, // REGLA: Solo pedidos de hoy
      },
    });

    if (pedidoActivo) {
      const error = new Error(
        `La Mesa #${mesa.numero} ya tiene una comanda activa hoy (${pedidoActivo.codigo}). Agrega productos a esa comanda en lugar de abrir una nueva.`
      );
      error.status = 409;
      throw error;
    }
  }

  const pedido = await prisma.$transaction(async (tx) => {
    let subtotal = 0;
    const itemsParaCrear = [];

    for (const item of items) {
      const filas = await tx.$queryRaw`
        SELECT pv.id, pv.precio, pv.tamano, pv.disponible AS variante_disponible, p.disponible AS producto_disponible
        FROM producto_variantes pv
        JOIN productos p ON p.id = pv."productoId"
        WHERE pv.id = ${item.productoVarianteId}
        FOR UPDATE
      `;
      const variante = filas[0];

      if (!variante) {
        const error = new Error(`La variante ${item.productoVarianteId} no existe`);
        error.status = 404;
        throw error;
      }

      if (!variante.variante_disponible || !variante.producto_disponible) {
        const error = new Error(
          `El producto/tamaño ID ${item.productoVarianteId} ("${variante.tamano}") está desactivado en la carta.`
        );
        error.status = 409;
        throw error;
      }

      let precioUnitario = Number(variante.precio);
      const agregadosParaCrear = [];

      if (item.agregados && item.agregados.length > 0) {
        for (const ag of item.agregados) {
          const agregado = await tx.agregado.findUnique({
            where: { id: ag.agregadoId },
            include: { precios: { where: { tamano: variante.tamano } } },
          });

          if (!agregado || !agregado.disponible) {
            const error = new Error("Uno de los agregados elegidos ya no está disponible");
            error.status = 409;
            throw error;
          }

          const precioAgregado = agregado.precios[0];
          if (!precioAgregado) {
            const error = new Error(`El agregado "${agregado.nombre}" no tiene precio para el tamaño "${variante.tamano}"`);
            error.status = 400;
            throw error;
          }

          const precioAg = Number(precioAgregado.precio);
          precioUnitario += precioAg;
          agregadosParaCrear.push({ agregadoId: agregado.id, precioUnitario: precioAg });
        }
      }

      subtotal += precioUnitario * item.cantidad;

      itemsParaCrear.push({
        productoVarianteId: item.productoVarianteId,
        cantidad: item.cantidad,
        precioUnitario,
        notas: item.notas,
        agregados: agregadosParaCrear.length > 0 ? { create: agregadosParaCrear } : undefined,
      });
    }

    const esPersonal = ["ADMIN", "MOZO", "PERSONALIZADO"].includes(rolSolicitante);
    const usuarioAtencion = esPersonal
      ? await tx.usuario.findUnique({
          where: { id: clienteId },
          select: { nombre: true, rol: true },
        })
      : null;
    if (esPersonal && !usuarioAtencion) {
      const error = new Error("El usuario que registra el pedido ya no existe");
      error.status = 401;
      throw error;
    }
    return tx.pedido.create({
      data: {
        codigo: generarCodigo(),
        clienteId,
        atendidoPorId: esPersonal ? clienteId : null,
        clienteNombre: clienteNombre ? clienteNombre.trim() : null,
        canal,
        estado: "PENDIENTE_PAGO",
        direccionId: canal === "DELIVERY" ? direccionId : null,
        mesaId: canal === "SALON" ? mesaId : null,
        subtotal,
        total: subtotal,
        items: { create: itemsParaCrear },
        pago: {
          create: { metodo: metodoPago, monto: subtotal, estado: "pendiente" },
        },
        ...(esPersonal && {
          historialAtencion: {
            create: {
              usuarioId: clienteId,
              usuarioNombre: usuarioAtencion.nombre,
              usuarioRol: usuarioAtencion.rol,
              accion: "REGISTRO",
            },
          },
        }),
      },
      include: {
        items: { include: { agregados: true } },
        pago: true,
        atendidoPor: { select: { id: true, nombre: true, rol: true } }, // 👈 NUEVO: Retorna responsable
        historialAtencion: { orderBy: { createdAt: "asc" } },
      },
    });
  });

  emitPedidoNuevo(pedido);
  return pedido;
}

async function confirmarPago(pedidoId, metodo, solicitante) {
  const pedido = await prisma.$transaction(async (tx) => {
    const actual = await tx.pedido.findUnique({
      where: { id: pedidoId },
      include: { pago: true },
    });

    if (!actual) {
      const error = new Error("Pedido no encontrado");
      error.status = 404;
      throw error;
    }
    validarAccesoCanal(solicitante, actual, "pedidos:cobrar");
    if (actual.estado !== "PENDIENTE_PAGO") {
      const error = new Error("Este pedido ya fue procesado");
      error.status = 409;
      throw error;
    }

    await tx.pago.update({
      where: { pedidoId },
      data: { estado: "pagado", metodo },
    });

    return tx.pedido.update({
      where: { id: pedidoId },
      data: { estado: "CONFIRMADO" },
      include: {
        items: true,
        pago: true,
        mesa: { select: { numero: true } },
        atendidoPor: { select: { id: true, nombre: true, rol: true } },
        historialAtencion: { orderBy: { createdAt: "asc" } },
      },
    });
  });

  emitPedidoActualizado(pedido);
  return pedido;
}

async function actualizarEstado(pedidoId, nuevoEstado, solicitante) {
  const resultado = await prisma.$transaction(async (tx) => {
    const pedido = await tx.pedido.findUnique({
      where: { id: pedidoId },
      include: { pago: true },
    });
    if (!pedido) {
      const error = new Error("Pedido no encontrado");
      error.status = 404;
      throw error;
    }

    if (solicitante && solicitante.rol === "REPARTIDOR") {
      const repartidor = await tx.repartidor.findUnique({ where: { usuarioId: solicitante.id } });
      if (!repartidor || pedido.repartidorId !== repartidor.id) {
        const error = new Error("No tienes asignado este pedido");
        error.status = 403;
        throw error;
      }
      const transicionRepartidorValida =
        pedido.canal === "DELIVERY" &&
        ((pedido.estado === "EN_PREPARACION" && nuevoEstado === "EN_CAMINO") ||
          (pedido.estado === "EN_CAMINO" && nuevoEstado === "ENTREGADO"));
      if (!transicionRepartidorValida) {
        const error = new Error(
          "El repartidor solo puede iniciar una entrega preparada o confirmar su entrega en curso"
        );
        error.status = 409;
        throw error;
      }
    }

    if (["MOZO", "PERSONALIZADO"].includes(solicitante?.rol)) {
      validarAccesoCanal(solicitante, pedido, "pedidos:cobrar");
      if (pedido.canal === "DELIVERY") {
        const error = new Error("El personal de salón no puede finalizar pedidos de delivery");
        error.status = 403;
        throw error;
      }
      if (nuevoEstado !== "ENTREGADO") {
        const error = new Error("El mozo solo puede finalizar pedidos ya cobrados");
        error.status = 403;
        throw error;
      }
      if (pedido.pago?.estado !== "pagado") {
        const error = new Error("Solo se puede finalizar un pedido después de registrar su pago");
        error.status = 409;
        throw error;
      }
    }

    if (
      pedido.canal === "DELIVERY" &&
      nuevoEstado === "ENTREGADO" &&
      pedido.estado !== "EN_CAMINO"
    ) {
      const error = new Error("Un pedido de delivery solo se puede marcar entregado cuando está en camino");
      error.status = 409;
      throw error;
    }

    const permitidos = TRANSICIONES_VALIDAS[pedido.estado] || [];
    const cierrePagadoDesdeConfirmado =
      nuevoEstado === "ENTREGADO" &&
      pedido.estado === "CONFIRMADO" &&
      pedido.pago?.estado === "pagado" &&
      pedido.canal !== "DELIVERY" &&
      ["ADMIN", "MOZO", "PERSONALIZADO"].includes(solicitante?.rol);
    if (!permitidos.includes(nuevoEstado) && !cierrePagadoDesdeConfirmado) {
      const error = new Error(`No se puede pasar de "${pedido.estado}" a "${nuevoEstado}"`);
      error.status = 409;
      throw error;
    }

    if (nuevoEstado === "EN_CAMINO" && pedido.canal !== "DELIVERY") {
      const error = new Error('El estado "EN_CAMINO" solo aplica a pedidos de delivery');
      error.status = 400;
      throw error;
    }

    const actualizado = await tx.pedido.update({
      where: { id: pedidoId },
      data: { estado: nuevoEstado },
    });

    if (
      nuevoEstado === "ENTREGADO" &&
      ["ADMIN", "MOZO", "PERSONALIZADO"].includes(solicitante?.rol)
    ) {
      const actor = await tx.usuario.findUnique({
        where: { id: solicitante.id },
        select: { nombre: true, rol: true },
      });
      if (!actor) {
        const error = new Error("El usuario que finaliza el pedido ya no existe");
        error.status = 401;
        throw error;
      }
      await tx.pedidoAtencion.create({
        data: {
          pedidoId,
          usuarioId: solicitante.id,
          usuarioNombre: actor.nombre,
          usuarioRol: actor.rol,
          accion: "FINALIZACION",
        },
      });
    }

    return actualizado;
  });

  emitPedidoActualizado(resultado);
  return resultado;
}

async function asignarRepartidor(pedidoId, repartidorId) {
  const resultado = await prisma.$transaction(async (tx) => {
    await tx.$queryRaw`
      SELECT id FROM pedidos WHERE id = ${pedidoId} FOR UPDATE
    `;
    const pedido = await tx.pedido.findUnique({ where: { id: pedidoId } });
    if (!pedido) {
      const error = new Error("Pedido no encontrado");
      error.status = 404;
      throw error;
    }
    if (pedido.canal !== "DELIVERY") {
      const error = new Error("Solo los pedidos de delivery necesitan repartidor");
      error.status = 400;
      throw error;
    }
    if (!["CONFIRMADO", "EN_PREPARACION"].includes(pedido.estado)) {
      const error = new Error("Solo se puede asignar repartidor a un pedido confirmado o en preparación");
      error.status = 409;
      throw error;
    }
    if (pedido.repartidorId) {
      const error = new Error("Este pedido ya tiene un repartidor asignado");
      error.status = 409;
      throw error;
    }

    await tx.$queryRaw`
      SELECT id FROM repartidores WHERE id = ${repartidorId} FOR UPDATE
    `;
    const repartidor = await tx.repartidor.findUnique({ where: { id: repartidorId } });
    if (!repartidor) {
      const error = new Error("Repartidor no encontrado");
      error.status = 404;
      throw error;
    }
    if (!repartidor.disponible) {
      const error = new Error("Ese repartidor ya no está disponible");
      error.status = 409;
      throw error;
    }

    const pedidosActivos = await tx.pedido.count({
      where: {
        repartidorId,
        estado: { notIn: ["ENTREGADO", "CANCELADO"] },
      },
    });
    if (pedidosActivos >= repartidor.capacidadPedidos) {
      const error = new Error("Ese repartidor ya alcanzó su capacidad de pedidos");
      error.status = 409;
      throw error;
    }

    return tx.pedido.update({
      where: { id: pedidoId },
      data: { repartidorId },
      include: { items: true, pago: true },
    });
  });

  emitPedidoActualizado(resultado);
  return resultado;
}

async function misEntregas(usuarioId) {
  const repartidor = await prisma.repartidor.findUnique({ where: { usuarioId } });
  if (!repartidor) {
    const error = new Error("No tienes un perfil de repartidor asociado");
    error.status = 404;
    throw error;
  }

  return prisma.pedido.findMany({
    where: { repartidorId: repartidor.id, estado: { not: "CANCELADO" } },
    include: {
      items: { include: { agregados: true } },
      pago: true,
      direccion: true,
      cliente: { select: { nombre: true, telefono: true } },
    },
    orderBy: { createdAt: "desc" },
    take: 20,
  });
}

async function listarPedidosCliente(clienteId) {
  return prisma.pedido.findMany({
    where: { clienteId },
    include: { items: { include: { agregados: true } }, pago: true },
    orderBy: { createdAt: "desc" },
  });
}

async function listarTodos({ desde, hasta } = {}, solicitante) {
  const inicio = desde ? new Date(desde) : new Date();
  if (!desde) inicio.setUTCHours(0, 0, 0, 0);
  const fin = hasta ? new Date(hasta) : new Date(inicio.getTime() + 24 * 60 * 60 * 1000);

  const where = { createdAt: { gte: inicio, lt: fin } };
  if (["MOZO", "PERSONALIZADO"].includes(solicitante?.rol)) {
    const permisos = solicitante.permisos || [];
    const canalesPermitidos = Object.entries(PERMISOS_POR_CANAL)
      .filter(([, permiso]) => permisos.includes(permiso))
      .map(([canal]) => canal);
    const filtrosCanales = canalesPermitidos.map((canal) => {
      if (canal === "SALON") return { canal: "SALON", mesaId: { not: null } };
      if (canal === "PARA_LLEVAR") return { canal: "SALON", mesaId: null };
      return { canal: "DELIVERY" };
    });
    if (filtrosCanales.length) where.OR = filtrosCanales;
    else where.id = -1;
  }

  return prisma.pedido.findMany({
    where,
    include: {
      items: { include: { agregados: true } },
      pago: true,
      cliente: { select: { nombre: true, telefono: true } },
      mesa: { select: { numero: true } },
      atendidoPor: { select: { id: true, nombre: true, rol: true } }, // 👈 NUEVO: Relación agregada al listado
      repartidor: { include: { usuario: { select: { nombre: true } } } },
      historialAtencion: { orderBy: { createdAt: "asc" } },
    },
    orderBy: { createdAt: "desc" },
  });
}

async function listarHistorial({ desde, hasta } = {}, solicitante) {
  const inicio = desde ? new Date(desde) : new Date();
  if (!desde) inicio.setUTCHours(0, 0, 0, 0);
  const fin = hasta ? new Date(hasta) : new Date(inicio.getTime() + 24 * 60 * 60 * 1000);
  const where = { createdAt: { gte: inicio, lt: fin } };

  if (solicitante?.rol === "REPARTIDOR") {
    const repartidor = await prisma.repartidor.findUnique({
      where: { usuarioId: solicitante.id },
      select: { id: true },
    });
    if (!repartidor) {
      const error = new Error("No tienes un perfil de repartidor asociado");
      error.status = 404;
      throw error;
    }
    where.repartidorId = repartidor.id;
  } else if (["MOZO", "PERSONALIZADO"].includes(solicitante?.rol)) {
    const permisos = solicitante.permisos || [];
    const canalesPermitidos = Object.entries(PERMISOS_POR_CANAL)
      .filter(([, permiso]) => permisos.includes(permiso))
      .map(([canal]) => canal);
    const filtrosCanales = canalesPermitidos.map((canal) => {
      if (canal === "SALON") return { canal: "SALON", mesaId: { not: null } };
      if (canal === "PARA_LLEVAR") return { canal: "SALON", mesaId: null };
      return { canal: "DELIVERY" };
    });

    where.AND = [
      {
        OR: [
          {
            historialAtencion: {
              some: {
                usuarioId: solicitante.id,
                accion: { in: ["REGISTRO", "CONTINUACION"] },
              },
            },
          },
          {
            atendidoPorId: solicitante.id,
            historialAtencion: {
              none: { accion: { in: ["REGISTRO", "CONTINUACION"] } },
            },
          },
        ],
      },
      filtrosCanales.length ? { OR: filtrosCanales } : { id: -1 },
    ];
  }

  return prisma.pedido.findMany({
    where,
    include: {
      items: { include: { agregados: true } },
      pago: true,
      cliente: { select: { nombre: true, telefono: true } },
      mesa: { select: { numero: true } },
      atendidoPor: { select: { id: true, nombre: true, rol: true } },
      repartidor: { include: { usuario: { select: { nombre: true } } } },
      historialAtencion: { orderBy: { createdAt: "asc" } },
    },
    orderBy: { createdAt: "desc" },
  });
}

async function auditarPedidos(filtros, solicitante) {
  const {
    desde,
    hasta,
    pagina,
    limite,
    busqueda,
    estado,
    canal,
    pago,
    iniciadoPor,
  } = filtros;
  const inicio = new Date(desde);
  const fin = new Date(hasta);
  const where = {
    createdAt: { gte: inicio, lt: fin },
    AND: [],
  };

  if (["MOZO", "PERSONALIZADO"].includes(solicitante?.rol)) {
    const permisos = solicitante.permisos || [];
    const canalesPermitidos = Object.entries(PERMISOS_POR_CANAL)
      .filter(([, permiso]) => permisos.includes(permiso))
      .map(([canalPermitido]) => canalPermitido);
    const filtrosCanales = canalesPermitidos.map((canalPermitido) => {
      if (canalPermitido === "SALON") return { canal: "SALON", mesaId: { not: null } };
      if (canalPermitido === "PARA_LLEVAR") return { canal: "SALON", mesaId: null };
      return { canal: "DELIVERY" };
    });
    where.AND.push(filtrosCanales.length ? { OR: filtrosCanales } : { id: -1 });
  }

  if (estado) where.estado = estado;
  if (canal === "SALON") where.AND.push({ canal: "SALON", mesaId: { not: null } });
  if (canal === "PARA_LLEVAR") where.AND.push({ canal: "SALON", mesaId: null });
  if (canal === "DELIVERY") where.canal = "DELIVERY";
  if (pago) {
    where.pago = { is: { estado: pago === "PAGADO" ? "pagado" : "pendiente" } };
  }
  if (iniciadoPor === "CLIENTE") {
    where.AND.push({
      historialAtencion: { none: { accion: "REGISTRO" } },
      atendidoPorId: null,
    });
  } else if (typeof iniciadoPor === "number") {
    where.AND.push({
      OR: [
        { historialAtencion: { some: { accion: "REGISTRO", usuarioId: iniciadoPor } } },
        {
          historialAtencion: { none: { accion: "REGISTRO" } },
          atendidoPorId: iniciadoPor,
        },
      ],
    });
  }
  if (busqueda) {
    where.AND.push({
      OR: [
        { codigo: { contains: busqueda, mode: "insensitive" } },
        { clienteNombre: { contains: busqueda, mode: "insensitive" } },
        { cliente: { nombre: { contains: busqueda, mode: "insensitive" } } },
      ],
    });
  }

  const [total, pedidos, iniciadores] = await prisma.$transaction([
    prisma.pedido.count({ where }),
    prisma.pedido.findMany({
      where,
      include: {
        items: { include: { agregados: true } },
        pago: true,
        cliente: { select: { nombre: true, telefono: true } },
        mesa: { select: { numero: true } },
        atendidoPor: { select: { id: true, nombre: true, rol: true } },
        repartidor: { include: { usuario: { select: { nombre: true } } } },
        historialAtencion: { orderBy: { createdAt: "asc" } },
      },
      orderBy: [{ createdAt: "desc" }, { id: "desc" }],
      skip: (pagina - 1) * limite,
      take: limite,
    }),
    prisma.usuario.findMany({
      where: solicitante?.rol === "ADMIN"
        ? { rol: { in: ["ADMIN", "MOZO", "PERSONALIZADO"] } }
        : { id: solicitante.id },
      select: { id: true, nombre: true, rol: true },
      orderBy: { nombre: "asc" },
    }),
  ]);

  return {
    pedidos,
    total,
    pagina,
    limite,
    totalPaginas: Math.ceil(total / limite),
    iniciadores,
  };
}

async function obtenerResumenPedidos({ desde, hasta } = {}) {
  const rango = {
    createdAt: {
      gte: desde ? new Date(desde) : new Date(0),
      lt: hasta ? new Date(hasta) : new Date(),
    },
  };
  const where = { ...rango, estado: { not: "CANCELADO" } };
  const wherePagados = {
    ...where,
    pago: { is: { estado: "pagado" } },
  };

  const [cantidad, facturacion, canales] = await prisma.$transaction([
    prisma.pedido.count({ where }),
    prisma.pedido.aggregate({ where: wherePagados, _sum: { total: true } }),
    prisma.pedido.groupBy({
      by: ["canal", "mesaId"],
      where,
      _count: { _all: true },
    }),
  ]);

  const resumenCanales = canales.reduce(
    (resumen, grupo) => {
      if (grupo.canal === "DELIVERY") resumen.delivery += grupo._count._all;
      else if (grupo.mesaId === null) resumen.paraLlevar += grupo._count._all;
      else resumen.salon += grupo._count._all;
      return resumen;
    },
    { salon: 0, paraLlevar: 0, delivery: 0 },
  );
  const totalFacturado = Number(facturacion._sum.total || 0);

  return {
    pedidosValidos: cantidad,
    totalFacturado,
    ticketPromedio: cantidad ? totalFacturado / cantidad : 0,
    canales: resumenCanales,
  };
}

async function obtenerRendimiento({ desde, hasta } = {}, solicitante) {
  const where = {
    createdAt: {
      gte: desde ? new Date(desde) : new Date(0),
      lt: hasta ? new Date(hasta) : new Date(),
    },
    usuarioRol: { in: ["ADMIN", "MOZO", "PERSONALIZADO"] },
  };
  if (solicitante.rol !== "ADMIN") {
    where.usuarioId = solicitante.id;
  }

  const eventos = await prisma.pedidoAtencion.findMany({
    where,
    select: {
      id: true,
      pedidoId: true,
      usuarioId: true,
      usuarioNombre: true,
      usuarioRol: true,
      accion: true,
      createdAt: true,
      pedido: {
        select: {
          codigo: true,
          canal: true,
          mesa: { select: { numero: true } },
          total: true,
        },
      },
    },
    orderBy: { createdAt: "desc" },
  });

  const equipo = new Map();
  const actividad = [];
  const picos = new Map();
  const diaInicio = desde ? new Date(desde) : new Date(0);
  const diaFin = hasta ? new Date(hasta) : new Date();
  const usarHoras = diaFin.getTime() - diaInicio.getTime() <= 24 * 60 * 60 * 1000;

  for (const evento of eventos) {
    if (!evento.usuarioId && solicitante.rol !== "ADMIN") continue;
    const clavePersona = evento.usuarioId ?? `historial:${evento.usuarioRol}:${evento.usuarioNombre}`;
    let resumen = equipo.get(clavePersona);
    if (!resumen) {
      resumen = {
        id: evento.usuarioId ?? clavePersona,
        nombre: evento.usuarioNombre,
        rol: evento.usuarioRol,
        registrados: 0,
        continuados: 0,
        finalizados: 0,
        pedidosRegistro: new Set(),
        pedidosContinuados: new Set(),
        pedidosFinalizados: new Set(),
      };
      equipo.set(clavePersona, resumen);
    }

    if (evento.accion === "REGISTRO") resumen.pedidosRegistro.add(evento.pedidoId);
    if (evento.accion === "CONTINUACION") resumen.pedidosContinuados.add(evento.pedidoId);
    if (evento.accion === "FINALIZACION") resumen.pedidosFinalizados.add(evento.pedidoId);

    const partesHoraLima = new Intl.DateTimeFormat("en-CA", {
      timeZone: "America/Lima",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      hourCycle: "h23",
    }).formatToParts(new Date(evento.createdAt));
    const partes = Object.fromEntries(partesHoraLima.map(({ type, value }) => [type, value]));
    const periodo = usarHoras
      ? `${partes.hour}:00`
      : `${partes.year}-${partes.month}-${partes.day}`;
    const pico = picos.get(periodo) || {
      periodo,
      actividad: 0,
      registrados: 0,
      continuados: 0,
      finalizados: 0,
    };
    pico.actividad += 1;
    if (evento.accion === "REGISTRO") pico.registrados += 1;
    if (evento.accion === "CONTINUACION") pico.continuados += 1;
    if (evento.accion === "FINALIZACION") pico.finalizados += 1;
    picos.set(periodo, pico);

    if (evento.usuarioId === solicitante.id) {
      actividad.push({
        id: evento.id,
        pedidoId: evento.pedidoId,
        codigo: evento.pedido.codigo,
        accion: evento.accion,
        fecha: evento.createdAt,
        canal: evento.pedido.canal,
        mesaNumero: evento.pedido.mesa?.numero ?? null,
        total: Number(evento.pedido.total),
      });
    }
  }

  const equipoResultado = [...equipo.values()].map((persona) => ({
    id: persona.id,
    nombre: persona.nombre,
    rol: persona.rol,
    registrados: persona.pedidosRegistro.size,
    continuados: persona.pedidosContinuados.size,
    finalizados: persona.pedidosFinalizados.size,
  }));
  const miRendimiento = equipoResultado.find((persona) => persona.id === solicitante.id) || {
    id: solicitante.id,
    nombre: "",
    rol: solicitante.rol,
    registrados: 0,
    continuados: 0,
    finalizados: 0,
  };

  return {
    propio: solicitante.rol !== "ADMIN",
    resumen: miRendimiento,
    equipo: solicitante.rol === "ADMIN"
      ? equipoResultado.sort((a, b) =>
          b.registrados + b.continuados + b.finalizados -
          (a.registrados + a.continuados + a.finalizados),
        )
      : [],
    picos: [...picos.values()].sort((a, b) => a.periodo.localeCompare(b.periodo)),
    actividad,
  };
}

async function obtenerPorId(id, solicitante) {
  let where = { id };

  if (solicitante.rol === "CLIENTE") {
    where.clienteId = solicitante.id;
  } else if (solicitante.rol === "REPARTIDOR") {
    const repartidor = await prisma.repartidor.findUnique({
      where: { usuarioId: solicitante.id },
      select: { id: true },
    });

    if (!repartidor) {
      const error = new Error("No tienes un perfil de repartidor asociado");
      error.status = 404;
      throw error;
    }

    where.repartidorId = repartidor.id;
  } else if (!["ADMIN", "MOZO", "PERSONALIZADO"].includes(solicitante.rol)) {
    const error = new Error("No tienes permiso para consultar este pedido");
    error.status = 403;
    throw error;
  }

  const pedido = await prisma.pedido.findUnique({
    where,
    include: {
      items: { include: { agregados: true } },
      pago: true,
      direccion: true,
      atendidoPor: { select: { id: true, nombre: true, rol: true } },
      historialAtencion: { orderBy: { createdAt: "asc" } },
    },
  });

  if (!pedido) {
    const error = new Error("Pedido no encontrado");
    error.status = 404;
    throw error;
  }
  validarAccesoCanal(solicitante, pedido, "pedidos:ver");
  return pedido;
}

async function agregarItemsAPedido(pedidoId, items, solicitante) {
  const pedidoActualizado = await prisma.$transaction(async (tx) => {
    const pedido = await tx.pedido.findUnique({
      where: { id: pedidoId },
      include: { pago: true },
    });

    if (!pedido) {
      const error = new Error("Pedido no encontrado");
      error.status = 404;
      throw error;
    }

    validarAccesoCanal(solicitante, pedido, "pedidos:crear");

    if (["ENTREGADO", "CANCELADO"].includes(pedido.estado)) {
      const error = new Error("No se pueden agregar productos a un pedido ya finalizado o cancelado");
      error.status = 409;
      throw error;
    }

    let subtotalAdicional = 0;
    const itemsParaCrear = [];

    for (const item of items) {
      const filas = await tx.$queryRaw`
        SELECT pv.id, pv.precio, pv.tamano, pv.disponible AS variante_disponible, p.disponible AS producto_disponible
        FROM producto_variantes pv
        JOIN productos p ON p.id = pv."productoId"
        WHERE pv.id = ${item.productoVarianteId}
        FOR UPDATE
      `;
      const variante = filas[0];

      if (!variante) {
        const error = new Error(`La variante ${item.productoVarianteId} no existe`);
        error.status = 404;
        throw error;
      }

      if (!variante.variante_disponible || !variante.producto_disponible) {
        const error = new Error("Uno de los productos elegidos ya no está disponible");
        error.status = 409;
        throw error;
      }

      let precioUnitario = Number(variante.precio);
      const agregadosParaCrear = [];

      if (item.agregados && item.agregados.length > 0) {
        for (const ag of item.agregados) {
          const agregado = await tx.agregado.findUnique({
            where: { id: ag.agregadoId },
            include: { precios: { where: { tamano: variante.tamano } } },
          });

          if (!agregado || !agregado.disponible) {
            const error = new Error("Uno de los agregados elegidos ya no está disponible");
            error.status = 409;
            throw error;
          }

          const precioAgregado = agregado.precios[0];
          if (!precioAgregado) {
            const error = new Error(`El agregado "${agregado.nombre}" no tiene precio para el tamaño "${variante.tamano}"`);
            error.status = 400;
            throw error;
          }

          const precioAg = Number(precioAgregado.precio);
          precioUnitario += precioAg;
          agregadosParaCrear.push({ agregadoId: agregado.id, precioUnitario: precioAg });
        }
      }

      subtotalAdicional += precioUnitario * item.cantidad;

      itemsParaCrear.push({
        pedidoId,
        productoVarianteId: item.productoVarianteId,
        cantidad: item.cantidad,
        precioUnitario,
        notas: item.notas,
        agregados: agregadosParaCrear.length > 0 ? { create: agregadosParaCrear } : undefined,
      });
    }

    for (const itemCrear of itemsParaCrear) {
      await tx.pedidoItem.create({ data: itemCrear });
    }

    const nuevoSubtotal = Number(pedido.subtotal) + subtotalAdicional;
    const nuevoTotal = Number(pedido.total) + subtotalAdicional;

    if (pedido.pago) {
      await tx.pago.update({
        where: { pedidoId },
        data: { monto: nuevoTotal },
      });
    }

    const actualizacion = {
      subtotal: nuevoSubtotal,
      total: nuevoTotal,
    };
    if (["ADMIN", "MOZO", "PERSONALIZADO"].includes(solicitante?.rol)) {
      const usuarioAtencion = await tx.usuario.findUnique({
        where: { id: solicitante.id },
        select: { nombre: true, rol: true },
      });
      if (!usuarioAtencion) {
        const error = new Error("El usuario que continúa el pedido ya no existe");
        error.status = 401;
        throw error;
      }

      actualizacion.atendidoPorId = solicitante.id;
      await tx.pedidoAtencion.create({
        data: {
          pedidoId,
          usuarioId: solicitante.id,
          usuarioNombre: usuarioAtencion.nombre,
          usuarioRol: usuarioAtencion.rol,
          accion: "CONTINUACION",
        },
      });
    }

    return tx.pedido.update({
      where: { id: pedidoId },
      data: actualizacion,
      include: {
        items: { include: { agregados: true } },
        pago: true,
        mesa: true,
        atendidoPor: { select: { id: true, nombre: true, rol: true } },
        cliente: { select: { nombre: true, telefono: true } },
        historialAtencion: { orderBy: { createdAt: "asc" } },
      },
    });
  });

  emitPedidoActualizado(pedidoActualizado);
  return pedidoActualizado;
}

module.exports = {
  crearPedido,
  confirmarPago,
  actualizarEstado,
  asignarRepartidor,
  misEntregas,
  listarPedidosCliente,
  listarTodos,
  listarHistorial,
  auditarPedidos,
  obtenerResumenPedidos,
  obtenerRendimiento,
  obtenerPorId,
  agregarItemsAPedido,
};