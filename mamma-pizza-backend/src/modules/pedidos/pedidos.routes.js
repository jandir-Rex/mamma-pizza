const { Router } = require("express");
const pedidosController = require("./pedidos.controller");
const verificarToken = require("../../middlewares/auth.middleware");
const permitirRoles = require("../../middlewares/role.middleware");

const router = Router();

router.use(verificarToken); // todas las rutas de pedidos requieren estar logueado

router.post("/", permitirRoles("CLIENTE", "ADMIN"), pedidosController.crearPedido);
router.get("/mios", permitirRoles("CLIENTE"), pedidosController.misPedidos);
router.get("/", permitirRoles("ADMIN"), pedidosController.listarTodos);
router.get("/:id", pedidosController.obtenerPorId);
router.patch("/:id/confirmar-pago", permitirRoles("ADMIN"), pedidosController.confirmarPago);
router.patch("/:id/estado", permitirRoles("ADMIN", "REPARTIDOR"), pedidosController.actualizarEstado);

module.exports = router;