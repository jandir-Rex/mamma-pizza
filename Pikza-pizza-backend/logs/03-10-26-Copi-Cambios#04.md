# [ROLES] [CANALES] [HISTORIAL DE PEDIDOS]

## Resumen

- La gestión de usuarios permite asignar a cada mozo los canales En salón, Para llevar y Delivery; también incluye la opción Todos los canales.
- Los pedidos visibles y consultables por un mozo se limitan en la API a los canales asignados.
- La creación de pedidos de salón y para llevar requiere permiso para el canal correspondiente. La creación de pedidos Delivery por el mozo continúa restringida.
- El detalle de pedido muestra quién lo registró y quiénes continuaron la comanda, con fecha y hora.
- Al agregar consumos a una comanda activa, el usuario que los agregó pasa a ser el responsable actual, conservando los eventos anteriores.
- La caché del panel de pedidos queda separada por usuario, rol y permisos; al abrir el registro se actualiza desde la API para evitar mostrar datos antiguos al cambiar de cuenta.
- El historial de atención muestra inicialmente solo el evento más reciente y permite expandir/contraer los eventos anteriores desde el mismo encabezado.
- La gestión de permisos incluye la opción independiente `pedidos:cobrar`; habilita para los canales autorizados registrar el método de pago real y finalizar pedidos ya cobrados, pero no cancelar ni cambiar otros estados.
- La confirmación de pago persiste el método elegido (efectivo, Yape o tarjeta) y el flujo permite cerrar un pedido pagado desde estado `CONFIRMADO`.
- Los registros históricos del responsable existente se copian a la nueva tabla durante la migración, cuando el dato anterior está disponible.

## Migración

Aplicar `prisma/migrations/20261003130000_pedido_atencion_canales_mozo/migration.sql` y regenerar Prisma Client. Los mozos existentes con permisos de pedidos reciben acceso inicial a En salón. Cerrar sesión y volver a entrar para refrescar los permisos JWT.

## Archivos principales

- `prisma/schema.prisma` y `prisma/migrations/20261003130000_pedido_atencion_canales_mozo/migration.sql`
- `src/modules/auth/auth.service.js`
- `src/modules/pedidos/pedidos.routes.js`, `pedidos.validation.js`, `pedidos.controller.js` y `pedidos.service.js`
- `Pikza-admin-web/src/pages/Administracion/GestionUsuarios.tsx`
- `Pikza-admin-web/src/pages/Administracion/RegistroPedidos.tsx`
- `Pikza-admin-web/src/components/PanelDetallePedido.tsx` y `DrawerCrearPedido.tsx`
- `Pikza-admin-web/src/types/pedido.ts` y `services/pedidosCache.ts`

## Verificación

- Prisma Client generado y esquema validado.
- `node --check` pasó en los archivos backend modificados.
- Prueba aislada confirmó filtro de canales, denegación al consultar un pedido de otro canal y cambio de responsable con evento de continuación.
- Prueba aislada confirmó que cobrar requiere permiso/canal, persiste el método, permite finalizar el pedido cobrado y deniega cancelar al mozo.
- ESLint pasó en los archivos frontend modificados y `vite build` compiló correctamente.
- `pnpm run build` llega al chequeo TypeScript y se detiene por el error previo `UserAddressCard.tsx:16` (variable `usuario` declarada y no utilizada), fuera de los cambios de este registro.
