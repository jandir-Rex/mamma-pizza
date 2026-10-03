const { Router } = require("express");
const repartidoresController = require("./repartidores.controller");
const verificarToken = require("../../middlewares/auth.middleware");
const permitirRoles = require("../../middlewares/role.middleware");
const { permitirPermisoParaRol } = permitirRoles;

const router = Router();

router.use(verificarToken);

// El propio repartidor actualiza su estado
router.patch("/ubicacion", permitirRoles("REPARTIDOR"), repartidoresController.actualizarUbicacion);
router.patch("/disponibilidad", permitirRoles("REPARTIDOR"), repartidoresController.actualizarDisponibilidad);
router.patch("/vehiculo", permitirRoles("REPARTIDOR"), repartidoresController.actualizarVehiculo);

// PERSONALIZADO requiere el permiso explícito; ADMIN conserva el acceso total.
router.get("/", permitirRoles("ADMIN", "PERSONALIZADO"), permitirPermisoParaRol("PERSONALIZADO", "reparto:gestion"), repartidoresController.listarTodos);
router.get("/disponibles", permitirRoles("ADMIN", "PERSONALIZADO"), permitirPermisoParaRol("PERSONALIZADO", "reparto:gestion"), repartidoresController.listarDisponibles);
router.get("/sugerido/:pedidoId", permitirRoles("ADMIN", "PERSONALIZADO"), permitirPermisoParaRol("PERSONALIZADO", "reparto:gestion"), repartidoresController.sugerirParaPedido);

module.exports = router;