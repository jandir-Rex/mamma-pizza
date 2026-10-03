# [DELIVERY] [DESPACHO] [CAPACIDAD] [BALANCEO]

## Cambios

- Se añadió capacidad máxima configurable por repartidor desde Gestión de Usuarios; el valor inicial para nuevos repartidores es 2 pedidos activos.
- El sistema impide bajar la capacidad por debajo de la cantidad de pedidos activos y bloquea asignaciones que excedan el cupo, con serialización en transacción para evitar sobreasignación concurrente.
- Un repartidor disponible puede tener varios pedidos hasta su capacidad. La disponibilidad representa que acepta pedidos; asignar o completar una entrega ya no la cambia automáticamente.
- La sugerencia de reparto solo considera repartidores disponibles, con ubicación registrada y cupo libre.
- El criterio de sugerencia equilibra al 50% distancia en línea recta y carga relativa (pedidos activos/capacidad); desempata por menor carga, distancia e identificador.
- La gestión de usuarios mantiene los perfiles de repartidor históricos al cambiar su rol, pero los pausa; no permite cambiar el rol mientras tengan pedidos activos.
- Se agregó `20261003173000_capacidad_pedidos_repartidor`; la migración no se aplicó a la base de datos.
- Se actualizó el README del backend.

## Pendiente para las siguientes etapas

- No se habilitó aún la asignación automática. Falta integrar el nuevo pedido desde cliente/app y definir el disparador cuando un pedido de pago en línea o contraentrega queda aceptado.
- Quedan pendientes pasarela de pago, cálculo de ETA vial, seguimiento de ubicación del repartidor por el cliente y notificaciones de estado.

## Verificación

- Pasaron `npx prisma validate` y `npx prisma generate`.
- Pasaron `npm run build` del panel y ESLint dirigido a Gestión de Usuarios.
- Pasó `node --check` en los módulos de pedidos, repartidores y autenticación modificados.
- No se desplegó ninguna migración ni se modificó la base remota.
- El build conserva el aviso existente sobre el tamaño del bundle JavaScript (>500 kB).
