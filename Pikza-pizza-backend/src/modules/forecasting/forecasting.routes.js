const { Router } = require("express");
const controller = require("./forecasting.controller");
const verificarToken = require("../../middlewares/auth.middleware");
const permitirRoles = require("../../middlewares/role.middleware");

const router = Router();

// Solo administradores: el pronostico y las compras sugeridas son informacion de gestion
router.use(verificarToken, permitirRoles("ADMIN"));

router.get("/status", controller.estado);
router.get("/overview", controller.resumen);
router.get("/history", controller.historial);
router.get("/accuracy", controller.precision);
router.get("/runs/:id", controller.obtener);
router.post("/generate", controller.generar);

module.exports = router;
