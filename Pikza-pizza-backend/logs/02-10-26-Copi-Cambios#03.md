# Cambios #03 — Alineación de pedidos y permisos por rol

**Fecha:** 02-10-26  
**Agente:** Copi

## Etiquetas

`#roles` `#permisos` `#repartidor` `#mozo` `#navegacion` `#rutas` `#backend` `#frontend`

## Resumen

Se alineó el menú y las rutas de pedidos con el rol del usuario. El repartidor queda limitado a “Mis entregas”; la sección de pedidos del panel se reserva a ADMIN y MOZO con permiso de lectura.

## Cambios aplicados

- La barra lateral muestra “Pedidos” solo para un MOZO con `pedidos:ver`, y “Mis entregas” para REPARTIDOR.
- Las rutas del panel de pedidos exigen ADMIN o MOZO y el permiso `pedidos:ver`.
- La redirección inicial usa el mismo permiso requerido por la ruta de pedidos.
- El formulario de usuarios solo presenta los permisos de pedidos aplicables a MOZO; al elegir otro rol, limpia la selección.
- Para MOZO, `pedidos:crear` implica `pedidos:ver`, ya que la interfaz de registro opera dentro de la sección de pedidos.
- El backend normaliza permisos al crear y editar personal: ADMIN recibe `*`, MOZO solo puede conservar `pedidos:ver` y `pedidos:crear`, y REPARTIDOR no conserva permisos de pedidos.
- Se actualizó la documentación de permisos en el README del backend.

## Archivos

- `Pikza-admin-web/src/layout/ControlSidebar.tsx`
- `Pikza-admin-web/src/App.tsx`
- `Pikza-admin-web/src/pages/Administracion/GestionUsuarios.tsx`
- `Pikza-pizza-backend/src/modules/auth/auth.service.js`
- `Pikza-pizza-backend/README.md`

## Verificación

- `node --check` pasó para `auth.service.js`.
- Prueba aislada de creación y edición: permisos irrelevantes descartados, REPARTIDOR queda sin permisos de pedidos, y `pedidos:crear` para MOZO conserva `pedidos:ver`.
- No se pudo completar el build de frontend: TypeScript no resuelve las declaraciones `vite/client` ni `node` del `node_modules` existente.
- ESLint no pudo ejecutarse por una dependencia faltante (`debug`) en el `node_modules` local.

## Alcance

Este cambio alinea el acceso a la sección de pedidos y los permisos del personal. No implementa asignación automática de entregas ni corrige otros enlaces del panel fuera de este flujo.
