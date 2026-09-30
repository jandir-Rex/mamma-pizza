const { Router } = require("express");
const pedidosController = require("./pedidos.controller");
const verificarToken = require("../../middlewares/auth.middleware");
const permitirRoles = require("../../middlewares/role.middleware");

const router = Router();

router.use(verificarToken);

router.post("/", permitirRoles("CLIENTE", "ADMIN", "MOZO"), pedidosController.crearPedido);
router.get("/mios", permitirRoles("CLIENTE"), pedidosController.misPedidos);
router.get("/repartidor/mis-entregas", permitirRoles("REPARTIDOR"), pedidosController.misEntregas);
router.get("/", permitirRoles("ADMIN"), pedidosController.listarTodos);
router.get("/:id", pedidosController.obtenerPorId);
router.patch("/:id/confirmar-pago", permitirRoles("ADMIN"), pedidosController.confirmarPago);
router.patch("/:id/estado", permitirRoles("ADMIN", "REPARTIDOR"), pedidosController.actualizarEstado);
router.patch("/:id/asignar-repartidor", permitirRoles("ADMIN"), pedidosController.asignarRepartidor);

module.exports = router;