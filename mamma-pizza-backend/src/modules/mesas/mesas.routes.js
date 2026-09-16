const { Router } = require("express");
const mesasController = require("./mesas.controller");
const verificarToken = require("../../middlewares/auth.middleware");
const permitirRoles = require("../../middlewares/role.middleware");

const router = Router();

router.use(verificarToken);

// Lectura: ADMIN y MOZO (el mozo necesita ver qué mesas están libres/ocupadas)
router.get("/", permitirRoles("ADMIN", "MOZO"), mesasController.listarMesas);
router.get("/estado", permitirRoles("ADMIN", "MOZO"), mesasController.estadoMesas);
router.get("/:id", permitirRoles("ADMIN", "MOZO"), mesasController.obtenerMesa);

// Escritura: solo ADMIN (gestión de mesas es administrativa)
router.post("/", permitirRoles("ADMIN"), mesasController.crearMesa);
router.put("/:id", permitirRoles("ADMIN"), mesasController.actualizarMesa);
router.delete("/:id", permitirRoles("ADMIN"), mesasController.eliminarMesa);

module.exports = router;