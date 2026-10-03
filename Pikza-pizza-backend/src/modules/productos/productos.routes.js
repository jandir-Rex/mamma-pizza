const { Router } = require("express");
const productosController = require("./productos.controller");
const verificarToken = require("../../middlewares/auth.middleware");
const permitirRoles = require("../../middlewares/role.middleware");
const { permitirPermisos } = permitirRoles;

const router = Router();

router.get("/menu", productosController.listarMenu);
router.get("/categorias", productosController.listarCategorias);
router.get("/:id", productosController.obtenerProducto);

router.post("/categorias", verificarToken, permitirRoles("ADMIN", "PERSONALIZADO"), permitirPermisos("productos:admin"), productosController.crearCategoria);
router.patch("/categorias/:id", verificarToken, permitirRoles("ADMIN", "PERSONALIZADO"), permitirPermisos("productos:admin"), productosController.actualizarAreaCategoria);
router.post("/", verificarToken, permitirRoles("ADMIN", "PERSONALIZADO"), permitirPermisos("productos:admin"), productosController.crearProducto);
router.put("/:id", verificarToken, permitirRoles("ADMIN", "PERSONALIZADO"), permitirPermisos("productos:admin"), productosController.actualizarProducto);
router.delete("/:id", verificarToken, permitirRoles("ADMIN", "PERSONALIZADO"), permitirPermisos("productos:admin"), productosController.desactivarProducto);
router.patch(
  "/variantes/:id/disponibilidad",
  verificarToken,
  permitirRoles("ADMIN", "PERSONALIZADO"),
  permitirPermisos("productos:admin"),
  productosController.actualizarDisponibilidadVariante
);

module.exports = router;