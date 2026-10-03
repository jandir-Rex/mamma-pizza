// src/middlewares/role.middleware.js

function permitirRoles(...rolesPermitidos) {
  return (req, res, next) => {
    if (!req.usuario || !rolesPermitidos.includes(req.usuario.rol)) {
      return res.status(403).json({ error: "No tienes permiso para esta acción" });
    }
    next();
  };
}

function permitirPermisos(...permisosRequeridos) {
  return (req, res, next) => {
    if (!req.usuario) {
      return res.status(401).json({ error: "No autenticado" });
    }

    // El ADMIN siempre tiene acceso total
    if (req.usuario.rol === "ADMIN") {
      return next();
    }

    const permisosUsuario = req.usuario.permisos || [];
    const tieneAcceso = permisosRequeridos.some((p) =>
      permisosUsuario.includes(p)
    );

    if (!tieneAcceso) {
      return res.status(403).json({
        error: "No tienes los permisos requeridos para esta acción",
      });
    }

    next();
  };
}

function permitirPermisoParaRol(rol, permiso) {
  const validarPermiso = permitirPermisos(permiso);
  return (req, res, next) => {
    if (!req.usuario) {
      return res.status(401).json({ error: "No autenticado" });
    }
    if (req.usuario.rol !== rol) return next();
    return validarPermiso(req, res, next);
  };
}

// Permite usarlo como función directa y también desestructurar permisos
permitirRoles.permitirRoles = permitirRoles;
permitirRoles.permitirPermisos = permitirPermisos;
permitirRoles.permitirPermisoParaRol = permitirPermisoParaRol;

module.exports = permitirRoles;