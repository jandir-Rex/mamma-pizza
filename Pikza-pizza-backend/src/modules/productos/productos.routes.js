const { Router } = require("express");
const productosController = require("./productos.controller");
const verificarToken = require("../../middlewares/auth.middleware");
const permitirRoles = require("../../middlewares/role.middleware");
const { permitirPermisos } = permitirRoles;
const { emitProductosCambiados } = require("../../sockets");

const router = Router();

// Tiempo real: cada cambio exitoso avisa a todos los paneles, enviando el producto ya actualizado
router.use((req, res, next) => {
  if (req.method === "GET") return next();

  let cuerpo;
  const enviarJson = res.json.bind(res);
  res.json = (data) => {
    cuerpo = data;
    return enviarJson(data);
  };

  res.on("finish", () => {
    if (res.statusCode >= 400) return;
    const esProducto = /^\/\d+$/.test(req.path);

    if (esProducto && req.method === "DELETE") {
      return emitProductosCambiados({ accion: "eliminar", id: Number(req.path.slice(1)) });
    }
    if ((esProducto || req.path === "/") && cuerpo && cuerpo.id) {
      const producto = JSON.parse(JSON.stringify(cuerpo));
      return emitProductosCambiados(
        producto.disponible === false
          ? { accion: "eliminar", id: producto.id }
          : { accion: "guardar", id: producto.id, producto }
      );
    }
    emitProductosCambiados({ accion: "recargar" });
  });

  next();
});

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