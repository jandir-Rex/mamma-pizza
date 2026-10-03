# [HISTORIAL] [PERMISOS] [MESERO] [REPARTIDOR]

## Resumen

- Se quitó el subtítulo “Consulta y auditoría”; queda “Historial de pedidos” y una descripción según el rol.
- El historial de `MOZO` y `PERSONALIZADO` muestra únicamente pedidos que registraron o continuaron y limita los resultados a sus canales autorizados.
- Se agregó acceso de historial para `REPARTIDOR`, limitado en backend a sus pedidos actualmente asignados.
- `ADMIN` conserva el historial completo. El detalle continúa siendo de solo lectura.
- Se documentaron el nuevo endpoint y las rutas de interfaz.

## Verificación

- Pasó `npm run build` y ESLint de las pantallas/rutas frontend afectadas.
- Pasó `node --check` para servicio, controlador y rutas backend.
- No se consultó una base de datos real.
