# [ROLES] [RBAC] [PERSONAL CONFIGURABLE] [PROTECCION ADMIN]

## Resumen

- Se añadió el rol `PERSONALIZADO` / “Configurable” para crear cuentas con acceso seleccionado por módulo, sin conceder acceso total.
- La administración puede asignar permisos para pedidos (incluidos canales y acciones), mesas, catálogo, repartidores y usuarios.
- Menú y rutas del panel muestran y autorizan los módulos web existentes según permisos, en lugar de asumir que todo personal es ADMIN o MOZO.
- La API aplica los permisos del rol configurable en cada módulo, incluso en consultas y operaciones de pedidos limitadas por canal.
- Un usuario configurable con `usuarios:admin` no puede modificar ni eliminar cuentas ADMIN, crear Administradores ni delegar permisos que no tenga.
- El acceso de ADMIN conserva el comportamiento existente de control total.
- La clave de caché de pedidos filtra permisos con tipos explícitos y se mantiene particionada por identidad, rol y permisos.

## Migración y activación

- Aplicar `prisma/migrations/20261003150000_rol_personalizado/migration.sql` mediante `npx prisma migrate deploy`.
- Regenerar el cliente Prisma con `npx prisma generate`.
- Asignar “Configurable” y seleccionar solo los permisos requeridos en Gestión de Usuarios.
- Cerrar e iniciar sesión con la cuenta para actualizar el JWT de rol/permisos.

## Nota de alcance

- Las opciones de Mesas y Repartidores habilitan los endpoints existentes. El panel web aún no cuenta con pantallas propias para administrar esos dos módulos.
- La gestión de Usuarios con acceso configurable queda limitada a cuentas que no sean ADMIN y no permite elevar permisos sobre los del gestor.

## Verificación

- Prisma valida el esquema y el cliente se generó correctamente.
- Pasaron las comprobaciones `node --check` para los archivos backend y pruebas aisladas de protección de ADMIN, límite de permisos delegados y autorización por módulo.
- `vite build` compiló correctamente.
- ESLint de los archivos frontend revisados terminó sin errores; permanece una advertencia de Fast Refresh ya existente en `AuthContext.tsx`.
- `tsc -b` solo reporta el error preexistente `UserAddressCard.tsx:16` por una variable `usuario` no utilizada.
