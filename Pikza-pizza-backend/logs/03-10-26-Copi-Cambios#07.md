# [ANALITICAS] [RENDIMIENTO PERSONAL] [AUDITORIA DE PEDIDOS]

## Resumen

- La página de analíticas conserva la vista general para ADMIN y ahora presenta al personal únicamente su propio rendimiento.
- El informe mide comandas registradas inicialmente, comandas distintas continuadas y pedidos finalizados por persona.
- Se agregaron picos de actividad por hora para Hoy y por fecha para los periodos de 7 días y mes.
- El personal ve una lista limitada a sus propios eventos; la auditoría detallada de pedidos y clientes queda exclusiva para ADMIN.
- `GET /pedidos/rendimiento` agrega todas las métricas en backend para ADMIN y limita la respuesta a `usuarioId` para MOZO/PERSONALIZADO.
- Al marcar un pedido como entregado por personal autorizado, el backend conserva el actor y fecha con el evento `FINALIZACION`.
- La agrupación de actividad horaria usa la zona de negocio `America/Lima`.

## Nota histórica

- Las finalizaciones anteriores a este cambio no registraban el usuario que las realizó y no se atribuyen retroactivamente.
- La cantidad de comandas registradas y continuadas usa los eventos que ya conserva el historial de atención.

## Verificación

- Prisma valida el esquema y no se requieren cambios de base de datos, pues `PedidoAtencion.accion` ya admite `FINALIZACION`.
- Las pruebas aisladas verifican que la vista personal filtre por `usuarioId`, el ADMIN reciba datos del equipo y el cierre registre al actor.
- `node --check`, ESLint de la página de analíticas y `vite build` pasaron.
- `tsc -b` permanece bloqueado por el error preexistente en `UserAddressCard.tsx:16` (variable `usuario` no utilizada).
