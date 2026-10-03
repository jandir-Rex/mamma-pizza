const { Router } = require("express");
const agregadosController = require("./agregados.controller");
const verificarToken = require("../../middlewares/auth.middleware");
const permitirRoles = require("../../middlewares/role.middleware");
const { permitirPermisos } = permitirRoles;

const router = Router();

router.get("/", agregadosController.listarAgregados);

router.post("/", verificarToken, permitirRoles("ADMIN", "PERSONALIZADO"), permitirPermisos("productos:admin"), agregadosController.crearAgregado);
router.put("/:id", verificarToken, permitirRoles("ADMIN", "PERSONALIZADO"), permitirPermisos("productos:admin"), agregadosController.actualizarAgregado);
router.patch("/:id/precio", verificarToken, permitirRoles("ADMIN", "PERSONALIZADO"), permitirPermisos("productos:admin"), agregadosController.actualizarPrecio);

module.exports = router;