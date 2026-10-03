# Cambios #02 — Control de acceso a pedidos por ID

**Fecha:** 02-10-26  
**Agente:** Copi

## Etiquetas

`#seguridad` `#autorizacion` `#pedidos` `#API` `#roles` `#backend`

## Resumen

Se restringió `GET /api/pedidos/:id` para que cada usuario solo pueda consultar pedidos permitidos para su rol y relación con el pedido.

## Cambios aplicados

- El controlador ahora pasa la identidad del usuario autenticado al servicio de pedidos.
- `ADMIN` y `MOZO` pueden consultar un pedido por ID.
- `CLIENTE` solo puede consultar pedidos asociados a su cuenta.
- `REPARTIDOR` solo puede consultar pedidos asignados a su perfil de repartidor.
- Un cliente que consulta un pedido ajeno recibe `404`, sin revelar si el pedido existe.
- Un repartidor sin perfil asociado recibe `404`; los roles no autorizados reciben `403`.
- Se actualizó la matriz de acceso a pedidos en el README del backend.

## Archivos

- `src/modules/pedidos/pedidos.controller.js`
- `src/modules/pedidos/pedidos.service.js`
- `README.md`

## Verificación

- Sintaxis JavaScript validada con `node --check` para controlador y servicio.
- Prueba aislada del servicio: acceso permitido a ADMIN, MOZO, CLIENTE propietario y REPARTIDOR asignado; acceso denegado a cliente ajeno y rol no permitido.

## Alcance

Este cambio protege la consulta individual por ID. No cambia el menú del panel, la asignación de repartidores ni el comportamiento de creación de pedidos.
