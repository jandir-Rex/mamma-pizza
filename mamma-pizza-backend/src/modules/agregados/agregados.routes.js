const { Router } = require("express");
const agregadosController = require("./agregados.controller");
const verificarToken = require("../../middlewares/auth.middleware");
const permitirRoles = require("../../middlewares/role.middleware");

const router = Router();

router.get("/", agregadosController.listarAgregados);

router.post("/", verificarToken, permitirRoles("ADMIN"), agregadosController.crearAgregado);
router.put("/:id", verificarToken, permitirRoles("ADMIN"), agregadosController.actualizarAgregado);
router.patch("/:id/precio", verificarToken, permitirRoles("ADMIN"), agregadosController.actualizarPrecio);

module.exports = router;