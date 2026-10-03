# [AUTORIZACION] [SINCRONIZACION DE SESION] [CAMBIO DE PERMISOS]

## Resumen

- Los endpoints protegidos consultan rol y permisos actuales desde base de datos y ya no autorizan usando permisos potencialmente obsoletos del JWT.
- Se añadió `GET /auth/sesion` para que el panel actualice el estado de autenticación sin pedir al usuario recargar manualmente.
- Al editar o eliminar una cuenta, el backend notifica a su sesión Socket.IO; el panel sincroniza el acceso y reconecta el socket con el estado vigente.
- Como alternativa si no hay conexión Socket.IO, el panel sincroniza al recuperar foco y cada 30 segundos.
- Si una cuenta se elimina o deja de tener rol de personal, el panel termina la sesión.

## Verificación

- `node --check` pasó en los archivos backend modificados.
- Las pruebas aisladas comprueban que una cuenta recibe su rol/permisos actuales aunque el JWT conserve claims anteriores y que las sesiones eliminadas se rechazan.
- `vite build` compiló correctamente y ESLint terminó sin errores.
- `tsc -b` continúa reportando el problema previo de `UserAddressCard.tsx:16` (variable `usuario` no utilizada).
