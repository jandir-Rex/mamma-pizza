// src/modules/pagos/pagos.routes.js
const { Router } = require("express");
const pagosController = require("./pagos.controller");
const verificarToken = require("../../middlewares/auth.middleware");
const permitirRoles = require("../../middlewares/role.middleware");
const { permitirPermisos } = permitirRoles;
const { recibirImagen } = require("../productos/imagenes");

const router = Router();

// Pública: el QR es justamente lo que el cliente debe ver para pagar.
// Va ANTES del middleware de autenticación.
router.get("/qr", pagosController.verQr);

// Todo lo demás es solo para quien administra los pagos
router.use(verificarToken, permitirRoles("ADMIN", "PERSONALIZADO"), permitirPermisos("pagos:admin"));

router.get("/config", pagosController.obtenerConfig);
router.put("/config", pagosController.actualizarConfig);
router.post("/qr", recibirImagen, pagosController.subirQr);
router.delete("/qr", pagosController.eliminarQr);

module.exports = router;