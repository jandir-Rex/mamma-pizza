const { Router } = require("express");
const mesasController = require("./mesas.controller");
const verificarToken = require("../../middlewares/auth.middleware");
const permitirRoles = require("../../middlewares/role.middleware");
const { permitirPermisoParaRol } = permitirRoles;

const router = Router();

router.use(verificarToken);

// Lectura: ADMIN y MOZO; PERSONALIZADO requiere el permiso explícito.
router.get("/", permitirRoles("ADMIN", "MOZO", "PERSONALIZADO"), permitirPermisoParaRol("PERSONALIZADO", "mesas:ver"), mesasController.listarMesas);
router.get("/estado", permitirRoles("ADMIN", "MOZO", "PERSONALIZADO"), permitirPermisoParaRol("PERSONALIZADO", "mesas:ver"), mesasController.estadoMesas);
router.get("/:id", permitirRoles("ADMIN", "MOZO", "PERSONALIZADO"), permitirPermisoParaRol("PERSONALIZADO", "mesas:ver"), mesasController.obtenerMesa);

// Escritura administrativa; PERSONALIZADO requiere el permiso explícito.
router.post("/", permitirRoles("ADMIN", "PERSONALIZADO"), permitirPermisoParaRol("PERSONALIZADO", "mesas:admin"), mesasController.crearMesa);
router.put("/:id", permitirRoles("ADMIN", "PERSONALIZADO"), permitirPermisoParaRol("PERSONALIZADO", "mesas:admin"), mesasController.actualizarMesa);
router.delete("/:id", permitirRoles("ADMIN", "PERSONALIZADO"), permitirPermisoParaRol("PERSONALIZADO", "mesas:admin"), mesasController.eliminarMesa);

module.exports = router;