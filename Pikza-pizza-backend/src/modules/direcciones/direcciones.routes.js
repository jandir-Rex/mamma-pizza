const { Router } = require("express");
const direccionesController = require("./direcciones.controller");
const verificarToken = require("../../middlewares/auth.middleware");
const permitirRoles = require("../../middlewares/role.middleware");

const router = Router();
router.use(verificarToken, permitirRoles("CLIENTE"));

router.post("/", direccionesController.crearDireccion);
router.get("/", direccionesController.listarPropias);
router.delete("/:id", direccionesController.eliminarDireccion);

module.exports = router;