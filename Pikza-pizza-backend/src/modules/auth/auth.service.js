// src/modules/auth/auth.service.js
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const prisma = require("../../config/prisma");
const { jwtSecret } = require("../../config/env");
const { PERMISOS_PERSONALIZADOS } = require("../../config/permisos");
const { emitirCambioAutorizacion } = require("../../sockets");

const PERMISOS_PEDIDOS_MOZO = new Set([
  "pedidos:ver",
  "pedidos:crear",
  "pedidos:cobrar",
  "pedidos:canal:SALON",
  "pedidos:canal:PARA_LLEVAR",
  "pedidos:canal:DELIVERY",
]);

function normalizarPermisos(rol, permisos = []) {
  if (rol === "ADMIN") return ["*"];
  if (rol === "PERSONALIZADO") {
    const permisosValidos = new Set(
      permisos.filter((permiso) => PERMISOS_PERSONALIZADOS.has(permiso)),
    );
    if (permisosValidos.has("pedidos:crear") || permisosValidos.has("pedidos:cobrar")) {
      permisosValidos.add("pedidos:ver");
    }
    if ([...permisosValidos].some((permiso) => permiso.startsWith("pedidos:canal:"))) {
      permisosValidos.add("pedidos:ver");
    }
    if (permisosValidos.has("mesas:admin")) {
      permisosValidos.add("mesas:ver");
    }
    return [...PERMISOS_PERSONALIZADOS].filter((permiso) => permisosValidos.has(permiso));
  }
  if (rol !== "MOZO") return [];
  const permisosValidos = new Set(
    permisos.filter((permiso) => PERMISOS_PEDIDOS_MOZO.has(permiso)),
  );
  if (permisosValidos.has("pedidos:crear") || permisosValidos.has("pedidos:cobrar")) {
    permisosValidos.add("pedidos:ver");
  }
  return [...PERMISOS_PEDIDOS_MOZO].filter((permiso) =>
    permisosValidos.has(permiso),
  );
}

function limitarPermisosDelegados(permisos, permisosSolicitante) {
  const permitidos = new Set(permisosSolicitante || []);
  return permisos.filter((permiso) => permitidos.has(permiso));
}

async function registrar({ nombre, email, password, telefono }) {
  const existente = await prisma.usuario.findUnique({ where: { email } });
  if (existente) {
    const error = new Error("Ese email ya está registrado");
    error.status = 409;
    throw error;
  }

  const passwordHash = await bcrypt.hash(password, 10);

  const usuario = await prisma.usuario.create({
    data: { 
      nombre, 
      email, 
      passwordHash, 
      telefono, 
      rol: "CLIENTE",
      permisos: [],
    },
  });

  return generarRespuesta(usuario);
}

async function crearStaff({
  nombre,
  email,
  password,
  telefono,
  rol,
  permisos = [],
  capacidadPedidos = 2,
}, solicitante) {
  if (solicitante?.rol === "PERSONALIZADO" && rol === "ADMIN") {
    const error = new Error("El rol Configurable no puede crear Administradores");
    error.status = 403;
    throw error;
  }

  const existente = await prisma.usuario.findUnique({ where: { email } });
  if (existente) {
    const error = new Error("Ese email ya está registrado");
    error.status = 409;
    throw error;
  }

  const passwordHash = await bcrypt.hash(password, 10);

  let permisosNormalizados = normalizarPermisos(rol, permisos);
  if (solicitante?.rol === "PERSONALIZADO") {
    permisosNormalizados = limitarPermisosDelegados(
      permisosNormalizados,
      solicitante.permisos,
    );
  }

  const usuario = await prisma.$transaction(async (tx) => {
    const creado = await tx.usuario.create({
      data: {
        nombre,
        email,
        passwordHash,
        telefono,
        rol,
        permisos: permisosNormalizados,
      },
    });

    if (rol === "REPARTIDOR") {
      await tx.repartidor.create({
        data: { usuarioId: creado.id, capacidadPedidos },
      });
    }

    return creado;
  });

  return generarRespuesta(usuario);
}

async function login({ email, password }) {
  const usuario = await prisma.usuario.findUnique({ where: { email } });
  if (!usuario) {
    const error = new Error("Credenciales inválidas");
    error.status = 401;
    throw error;
  }

  const passwordValida = await bcrypt.compare(password, usuario.passwordHash);
  if (!passwordValida) {
    const error = new Error("Credenciales inválidas");
    error.status = 401;
    throw error;
  }

  return generarRespuesta(usuario);
}

async function obtenerSesion(usuarioId) {
  const usuario = await prisma.usuario.findUnique({
    where: { id: usuarioId },
    select: {
      id: true,
      nombre: true,
      email: true,
      rol: true,
      permisos: true,
      telefono: true,
      dni: true,
      direccion: true,
      ciudad: true,
    },
  });
  if (!usuario) {
    const error = new Error("La cuenta asociada a esta sesión ya no existe");
    error.status = 401;
    throw error;
  }
  return { ...usuario, permisos: usuario.permisos || [] };
}

// En src/modules/auth/auth.service.js:
async function actualizarPerfil(usuarioId, datos) {
  const usuario = await prisma.usuario.findUnique({ where: { id: usuarioId } });
  if (!usuario) {
    const error = new Error("Usuario no encontrado");
    error.status = 404;
    throw error;
  }

  const dataParaActualizar = {};

  if (datos.nombre) dataParaActualizar.nombre = datos.nombre.trim();
  if (datos.telefono !== undefined) dataParaActualizar.telefono = datos.telefono ? datos.telefono.trim() : null;
  if (datos.dni !== undefined) dataParaActualizar.dni = datos.dni ? datos.dni.trim() : null;
  if (datos.direccion !== undefined) dataParaActualizar.direccion = datos.direccion ? datos.direccion.trim() : null;
  if (datos.ciudad !== undefined) dataParaActualizar.ciudad = datos.ciudad ? datos.ciudad.trim() : null;

  // Si desea cambiar contraseña, valida la actual
  if (datos.passwordNuevo) {
    if (!datos.passwordActual) {
      const error = new Error("Debes ingresar tu contraseña actual para cambiarla");
      error.status = 400;
      throw error;
    }

    const passwordValida = await bcrypt.compare(datos.passwordActual, usuario.passwordHash);
    if (!passwordValida) {
      const error = new Error("La contraseña actual es incorrecta");
      error.status = 400;
      throw error;
    }

    dataParaActualizar.passwordHash = await bcrypt.hash(datos.passwordNuevo, 10);
  }

  const actualizado = await prisma.usuario.update({
    where: { id: usuarioId },
    data: dataParaActualizar,
  });

  return {
    id: actualizado.id,
    nombre: actualizado.nombre,
    email: actualizado.email,
    telefono: actualizado.telefono,
    dni: actualizado.dni,
    direccion: actualizado.direccion,
    ciudad: actualizado.ciudad,
    rol: actualizado.rol,
    permisos: actualizado.permisos || [],
  };
}

// 1. Listar todos los usuarios (Staff y Clientes)
async function listarUsuarios({ rol, busqueda } = {}) {
  const where = {};
  
  if (rol && rol !== "TODOS") {
    where.rol = rol;
  }

  if (busqueda && busqueda.trim()) {
    where.OR = [
      { nombre: { contains: busqueda.trim(), mode: "insensitive" } },
      { email: { contains: busqueda.trim(), mode: "insensitive" } },
    ];
  }

  const usuarios = await prisma.usuario.findMany({
    where,
    include: {
      direcciones: true, // 👈 Trae todas las direcciones de la app
      repartidor: { select: { capacidadPedidos: true } },
      _count: {
        select: { pedidos: true }, // 👈 Cuenta cuántos pedidos lleva
      },
    },
    orderBy: { createdAt: "desc" },
  });

  return usuarios.map((u) => ({
    id: u.id,
    nombre: u.nombre,
    email: u.email,
    telefono: u.telefono,
    rol: u.rol,
    permisos: u.permisos || [],
    capacidadPedidos: u.repartidor?.capacidadPedidos ?? null,
    createdAt: u.createdAt,
    direcciones: u.direcciones || [],
    totalPedidos: u._count.pedidos,
  }));
}
// Un administrador o gestor autorizado actualiza una cuenta (incluido reset de contraseña).
async function actualizarUsuarioPorAdmin(id, datos, solicitante) {
  const usuario = await prisma.usuario.findUnique({
    where: { id },
    include: { repartidor: true },
  });
  if (!usuario) {
    const error = new Error("Usuario no encontrado");
    error.status = 404;
    throw error;
  }

  const adminId = solicitante.id;
  const esConfigurable = solicitante.rol === "PERSONALIZADO";

  if (esConfigurable && (usuario.rol === "ADMIN" || datos.rol === "ADMIN")) {
    const error = new Error("El rol Configurable no puede modificar cuentas Administrador");
    error.status = 403;
    throw error;
  }

  // Protección: No puedes degradar tu propia cuenta de Admin
  if (usuario.id === adminId && datos.rol && datos.rol !== "ADMIN") {
    const error = new Error("No puedes quitarte el rol de Administrador a ti mismo");
    error.status = 400;
    throw error;
  }

  const rolActualizado = datos.rol ?? usuario.rol;
  if (datos.capacidadPedidos !== undefined && rolActualizado !== "REPARTIDOR") {
    const error = new Error("La capacidad de pedidos solo aplica a usuarios con rol de repartidor");
    error.status = 400;
    throw error;
  }
  const permisosNormalizados = normalizarPermisos(
    rolActualizado,
    datos.permisos ?? usuario.permisos ?? [],
  );
  const { capacidadPedidos, ...datosUsuario } = datos;
  const dataParaActualizar = {
    ...datosUsuario,
    permisos: esConfigurable
      ? limitarPermisosDelegados(permisosNormalizados, solicitante.permisos)
      : permisosNormalizados,
  };

  // Si el Admin le cambió la contraseña al usuario
  if (datos.password) {
    dataParaActualizar.passwordHash = await bcrypt.hash(datos.password, 10);
    delete dataParaActualizar.password;
  }

  const actualizado = await prisma.$transaction(async (tx) => {
    if (usuario.repartidor) {
      await tx.$queryRaw`
        SELECT id FROM repartidores WHERE id = ${usuario.repartidor.id} FOR UPDATE
      `;
    }

    const actualizadoUsuario = await tx.usuario.update({
      where: { id },
      data: dataParaActualizar,
      select: {
        id: true,
        nombre: true,
        email: true,
        telefono: true,
        rol: true,
        permisos: true,
      },
    });

    if (rolActualizado === "REPARTIDOR") {
      if (usuario.repartidor) {
        if (capacidadPedidos !== undefined) {
          const pedidosActivos = await tx.pedido.count({
            where: {
              repartidorId: usuario.repartidor.id,
              estado: { notIn: ["ENTREGADO", "CANCELADO"] },
            },
          });
          if (capacidadPedidos < pedidosActivos) {
            const error = new Error(`La capacidad no puede ser menor que sus ${pedidosActivos} pedidos activos`);
            error.status = 409;
            throw error;
          }
          await tx.repartidor.update({
            where: { id: usuario.repartidor.id },
            data: { capacidadPedidos },
          });
        }
      } else {
        await tx.repartidor.create({
          data: { usuarioId: id, capacidadPedidos: capacidadPedidos ?? 2 },
        });
      }
    } else if (usuario.repartidor) {
      const pedidosActivos = await tx.pedido.count({
        where: {
          repartidorId: usuario.repartidor.id,
          estado: { notIn: ["ENTREGADO", "CANCELADO"] },
        },
      });
      if (pedidosActivos > 0) {
        const error = new Error("No se puede quitar el rol de repartidor mientras tenga pedidos activos");
        error.status = 409;
        throw error;
      }
      await tx.repartidor.update({
        where: { id: usuario.repartidor.id },
        data: { disponible: false },
      });
    }

    return actualizadoUsuario;
  });
  emitirCambioAutorizacion(id);
  return actualizado;
}

// Un administrador o gestor autorizado elimina una cuenta.
async function eliminarUsuario(id, solicitante) {
  if (id === solicitante.id) {
    const error = new Error("No puedes eliminar tu propia cuenta");
    error.status = 400;
    throw error;
  }

  const usuario = await prisma.usuario.findUnique({ where: { id } });
  if (!usuario) {
    const error = new Error("Usuario no encontrado");
    error.status = 404;
    throw error;
  }

  if (solicitante.rol === "PERSONALIZADO" && usuario.rol === "ADMIN") {
    const error = new Error("El rol Configurable no puede eliminar cuentas Administrador");
    error.status = 403;
    throw error;
  }

  await prisma.usuario.delete({ where: { id } });
  emitirCambioAutorizacion(id);
  return { mensaje: "Usuario eliminado correctamente" };
}

function generarRespuesta(usuario) {
  const token = jwt.sign(
    {
      id: usuario.id,
      rol: usuario.rol,
      permisos: usuario.permisos || [],
    },
    jwtSecret,
    { expiresIn: "7d" }
  );

  return {
    token,
    usuario: {
      id: usuario.id,
      nombre: usuario.nombre,
      email: usuario.email,
      rol: usuario.rol,
      permisos: usuario.permisos || [],
    },
  };
}

module.exports = {
  registrar,
  login,
  obtenerSesion,
  crearStaff,
  actualizarPerfil,
  listarUsuarios,
  actualizarUsuarioPorAdmin,
  eliminarUsuario,
};