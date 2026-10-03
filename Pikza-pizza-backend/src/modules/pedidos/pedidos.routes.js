// src/modules/pedidos/pedidos.routes.js
const { Router } = require("express");
const pedidosController = require("./pedidos.controller");
const verificarToken = require("../../middlewares/auth.middleware");
const { permitirRoles, permitirPermisos } = require("../../middlewares/role.middleware");

const router = Router();

router.use(verificarToken);

function permitirClienteOPermisoPedido(req, res, next) {
  if (req.usuario.rol === "CLIENTE") return next();
  return permitirPermisos("pedidos:crear")(req, res, next);
}

// Creación y agregación de items
router.post("/", permitirRoles("CLIENTE", "ADMIN", "MOZO", "PERSONALIZADO"), permitirClienteOPermisoPedido, pedidosController.crearPedido);
router.post("/:id/items", permitirRoles("ADMIN", "MOZO", "PERSONALIZADO"), permitirPermisos("pedidos:crear"), pedidosController.agregarItems);

// Consultas
router.get("/mios", permitirRoles("CLIENTE"), pedidosController.misPedidos);
router.get("/repartidor/mis-entregas", permitirRoles("REPARTIDOR"), pedidosController.misEntregas);
router.get(
  "/historial",
  permitirRoles("ADMIN", "MOZO", "PERSONALIZADO", "REPARTIDOR"),
  (req, res, next) => req.usuario.rol === "REPARTIDOR"
    ? next()
    : permitirPermisos("pedidos:ver")(req, res, next),
  pedidosController.listarHistorial,
);
router.get("/auditoria", permitirRoles("ADMIN", "MOZO", "PERSONALIZADO"), permitirPermisos("pedidos:ver"), pedidosController.auditarPedidos);
router.get("/resumen", permitirRoles("ADMIN"), permitirPermisos("pedidos:ver"), pedidosController.obtenerResumenPedidos);
router.get("/", permitirRoles("ADMIN", "MOZO", "PERSONALIZADO"), permitirPermisos("pedidos:ver"), pedidosController.listarTodos);
router.get("/rendimiento", permitirRoles("ADMIN", "MOZO", "PERSONALIZADO"), permitirPermisos("pedidos:ver"), pedidosController.obtenerRendimiento);
router.get("/:id", pedidosController.obtenerPorId);

// Operaciones de Caja y Reparto
router.patch("/:id/confirmar-pago", permitirRoles("ADMIN", "MOZO", "PERSONALIZADO"), permitirPermisos("pedidos:cobrar"), pedidosController.confirmarPago);
router.patch("/:id/estado", permitirRoles("ADMIN", "MOZO", "PERSONALIZADO", "REPARTIDOR"), pedidosController.actualizarEstado);
router.patch("/:id/asignar-repartidor", permitirRoles("ADMIN", "PERSONALIZADO"), permitirPermisos("reparto:gestion"), pedidosController.asignarRepartidor);

module.exports = router;