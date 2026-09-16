const { Router } = require("express");
const repartidoresController = require("./repartidores.controller");
const verificarToken = require("../../middlewares/auth.middleware");
const permitirRoles = require("../../middlewares/role.middleware");

const router = Router();

router.use(verificarToken);

// El propio repartidor actualiza su estado
router.patch("/ubicacion", permitirRoles("REPARTIDOR"), repartidoresController.actualizarUbicacion);
router.patch("/disponibilidad", permitirRoles("REPARTIDOR"), repartidoresController.actualizarDisponibilidad);
router.patch("/vehiculo", permitirRoles("REPARTIDOR"), repartidoresController.actualizarVehiculo);

// El admin consulta y asigna
router.get("/", permitirRoles("ADMIN"), repartidoresController.listarTodos);
router.get("/disponibles", permitirRoles("ADMIN"), repartidoresController.listarDisponibles);
router.get("/sugerido/:pedidoId", permitirRoles("ADMIN"), repartidoresController.sugerirParaPedido);

module.exports = router;