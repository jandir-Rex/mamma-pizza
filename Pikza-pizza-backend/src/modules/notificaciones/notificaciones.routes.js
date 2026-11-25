const { Router } = require("express");
const { z } = require("zod");
const verificarToken = require("../../middlewares/auth.middleware");
const notificacionesService = require("./notificaciones.service");

const router = Router();
const esquemaRegistro = z.object({
  app: z.enum(["cliente", "repartidor"]),
  fid: z.string().min(10).max(128),
});
const esquemaEliminacion = z.object({
  fid: z.string().min(10).max(128),
});

router.use(verificarToken);

router.post("/instalacion", async (req, res, next) => {
  const validacion = esquemaRegistro.safeParse(req.body);
  if (!validacion.success) {
    return res.status(400).json({ error: "FID o aplicación de notificaciones inválidos" });
  }

  try {
    await notificacionesService.registrarInstalacion({
      usuarioId: req.usuario.id,
      rol: req.usuario.rol,
      ...validacion.data,
    });
    return res.json({ ok: true });
  } catch (error) {
    return next(error);
  }
});

router.delete("/instalacion", async (req, res, next) => {
  const validacion = esquemaEliminacion.safeParse(req.body);
  if (!validacion.success) {
    return res.status(400).json({ error: "FID de notificaciones inválido" });
  }

  try {
    await notificacionesService.eliminarInstalacion({
      usuarioId: req.usuario.id,
      fid: validacion.data.fid,
    });
    return res.json({ ok: true });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
