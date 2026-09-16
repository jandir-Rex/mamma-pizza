const { Router } = require("express");
const productosController = require("./productos.controller");
const verificarToken = require("../../middlewares/auth.middleware");
const permitirRoles = require("../../middlewares/role.middleware");

const router = Router();

router.get("/menu", productosController.listarMenu);
router.get("/categorias", productosController.listarCategorias);
router.get("/:id", productosController.obtenerProducto);

router.post("/categorias", verificarToken, permitirRoles("ADMIN"), productosController.crearCategoria);
router.post("/", verificarToken, permitirRoles("ADMIN"), productosController.crearProducto);
router.put("/:id", verificarToken, permitirRoles("ADMIN"), productosController.actualizarProducto);
router.delete("/:id", verificarToken, permitirRoles("ADMIN"), productosController.desactivarProducto);
router.patch(
  "/variantes/:id/disponibilidad",
  verificarToken,
  permitirRoles("ADMIN"),
  productosController.actualizarDisponibilidadVariante
);

module.exports = router;