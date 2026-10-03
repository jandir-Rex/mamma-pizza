// src/modules/auth/auth.routes.js
const { Router } = require("express");
const authController = require("./auth.controller");
const verificarToken = require("../../middlewares/auth.middleware");
const permitirRoles = require("../../middlewares/role.middleware");
const { permitirPermisos } = permitirRoles;
const { loginLimiter } = require("../../middlewares/rateLimit.middleware");

const router = Router();

// Rutas Públicas
router.post("/registro", authController.registrar);
router.post("/login", loginLimiter, authController.login);

// Rutas para cualquier usuario autenticado (Mi Perfil)
router.patch("/perfil", verificarToken, authController.actualizarPerfil);
router.get("/sesion", verificarToken, authController.obtenerSesion);

// Gestión de usuarios para ADMIN y para PERSONALIZADO con usuarios:admin.
router.get("/usuarios", verificarToken, permitirRoles("ADMIN", "PERSONALIZADO"), permitirPermisos("usuarios:admin"), authController.listarUsuarios);
router.post("/staff", verificarToken, permitirRoles("ADMIN", "PERSONALIZADO"), permitirPermisos("usuarios:admin"), authController.crearStaff);
router.put("/usuarios/:id", verificarToken, permitirRoles("ADMIN", "PERSONALIZADO"), permitirPermisos("usuarios:admin"), authController.actualizarUsuarioAdmin);
router.delete("/usuarios/:id", verificarToken, permitirRoles("ADMIN", "PERSONALIZADO"), permitirPermisos("usuarios:admin"), authController.eliminarUsuario);

module.exports = router;