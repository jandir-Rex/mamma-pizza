// src/config/permisos.js
const PERMISOS = {
  // Módulo Pedidos
  PEDIDOS_VER: "pedidos:ver",
  PEDIDOS_CREAR: "pedidos:crear",
  PEDIDOS_COBRAR: "pedidos:cobrar",
  PEDIDOS_ESTADO: "pedidos:estado",
  
  // Módulo Mesas
  MESAS_VER: "mesas:ver",
  MESAS_ADMIN: "mesas:admin",

  // Módulo Catálogo
  PRODUCTOS_ADMIN: "productos:admin",

  // Módulo Repartidores
  REPARTO_GESTION: "reparto:gestion",

  // Módulo Usuarios / Staff
  USUARIOS_ADMIN: "usuarios:admin",
};

const PERMISOS_PERSONALIZADOS = new Set(
  Object.values(PERMISOS).filter((permiso) => permiso !== PERMISOS.PEDIDOS_ESTADO),
);

module.exports = PERMISOS;
module.exports.PERMISOS_PERSONALIZADOS = PERMISOS_PERSONALIZADOS;