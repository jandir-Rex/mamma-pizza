const { Router } = require("express");
const authController = require("./auth.controller");
const verificarToken = require("../../middlewares/auth.middleware");
const permitirRoles = require("../../middlewares/role.middleware");
const { loginLimiter } = require("../../middlewares/rateLimit.middleware");

const router = Router();

router.post("/registro", authController.registrar);
router.post("/login", loginLimiter, authController.login);
router.post("/staff", verificarToken, permitirRoles("ADMIN"), authController.crearStaff);

module.exports = router;