# Guía de integración móvil: pedidos, pagos y delivery

> Documento de traspaso para integrar la app móvil con la API existente. Describe el contrato observado en el backend y distingue expresamente lo implementado de lo que todavía requiere desarrollo. No tratar las propuestas futuras como endpoints disponibles.

## 1. Entorno y reglas generales

- API: `https://<host>/api`; en desarrollo local: `http://localhost:4000/api`.
- JSON UTF-8 en solicitudes y respuestas.
- Las rutas protegidas requieren `Authorization: Bearer <token>`.
- El token se obtiene en `POST /auth/login` o `POST /auth/registro`. La app debe conservarlo de forma segura y enviarlo en cada solicitud protegida.
- Los errores usan un estado HTTP apropiado y un objeto JSON con `error` para errores gestionados. La app debe presentar los errores de validación/conflicto y permitir reintentar según corresponda.
- Los importes están en PEN y se deben mostrar como moneda peruana. El servidor recalcula precios a partir de IDs de variantes/agregados; la app nunca debe enviar ni confiar en precios calculados por el cliente.
- Los IDs son enteros. Los estados, roles, canales y métodos de pago son enumeraciones exactas y sensibles a mayúsculas.
- El menú es de consulta pública. Cuenta, direcciones y pedidos requieren sesión.

## 2. Flujo de cliente que la API soporta hoy

### A. Crear cuenta o iniciar sesión

`POST /auth/registro`

```json
{
  "nombre": "Nombre Apellido",
  "email": "cliente@example.com",
  "password": "contraseña",
  "telefono": "999888777"
}
```

`POST /auth/login`

```json
{
  "email": "cliente@example.com",
  "password": "contraseña"
}
```

El registro crea un usuario `CLIENTE`. El teléfono, si se envía, debe tener exactamente 9 dígitos. La respuesta contiene `token` y `usuario`; el JWT actual expira en 7 días. Usar el token devuelto como Bearer. `GET /auth/sesion` devuelve los datos vigentes del usuario autenticado, pero no renueva el token.

### B. Mostrar productos y disponibilidad

`GET /productos/menu` (público)

Devuelve una lista de productos disponibles con sus variantes, IDs, tamaño, precio y disponibilidad, además de categoría/subcategoría. Construir el carrito con `productoVarianteId`; enviar también `agregadoId` si se seleccionaron extras.

`GET /agregados` (público según la ruta actual) devuelve los agregados disponibles y sus precios por tamaño. El backend vuelve a comprobar que variante y agregados estén disponibles y tengan precio para el tamaño solicitado al crear el pedido. Un fallo de disponibilidad/precio puede devolver conflicto/validación; mostrarlo y pedir al cliente que revise el carrito.

### C. Registrar/editar direcciones del cliente

Todas las rutas de direcciones son exclusivas de `CLIENTE` autenticado.

- `GET /direcciones`: direcciones guardadas del cliente.
- `POST /direcciones`:

```json
{
  "zona": "Dirección legible",
  "referencia": "Referencia opcional",
  "lat": -12.0,
  "lng": -77.0
}
```

- `DELETE /direcciones/:id`: elimina una dirección propia; responde `204` sin cuerpo. Una dirección con pedidos activos no se puede eliminar (`409`).

`zona` debe tener al menos 2 caracteres. `lat` y `lng` deben ser números. El esquema actual no impone límites geográficos, zonas de cobertura ni validación de coordenadas dentro del Perú; la app debe capturar coordenadas reales del mapa/dispositivo y no sustituirlas por valores ficticios. Se recomienda ofrecer selección/marcador manual si la geolocalización falla o el cliente no da permiso.

### D. Crear pedido de delivery

`POST /pedidos` (token de cliente requerido)

```json
{
  "canal": "DELIVERY",
  "direccionId": 123,
  "metodoPago": "EFECTIVO",
  "items": [
    {
      "productoVarianteId": 456,
      "cantidad": 2,
      "notas": "Sin cebolla",
      "agregados": [{ "agregadoId": 7 }]
    }
  ]
}
```

Campos válidos:

- `canal`: `DELIVERY` para domicilio o `SALON`.
- Para `DELIVERY`, `direccionId` es obligatorio y debe pertenecer a la cuenta autenticada.
- `metodoPago`: enum actual `YAPE`, `EFECTIVO` o `TARJETA`.
- `items`: debe incluir al menos un elemento. Cada elemento requiere `productoVarianteId` y `cantidad` entera positiva; `notas` es opcional; `agregados` es opcional.
- No enviar `clienteId`, `subtotal`, `total`, `precioUnitario`, estado, asignación de repartidor ni datos de tarjeta; no forman parte del contrato de creación confiable.

El backend calcula importes y crea pedido, pago pendiente e items en una transacción. La respuesta actual incluye datos del pedido, items, pago, responsable y, cuando corresponda, historial de atención. Los datos principales a guardar en el estado local de la app son `id`, `codigo`, `estado`, `total`, `createdAt`, `pago` y `items`.

**Importante:** el pedido se crea con `estado: "PENDIENTE_PAGO"` y el pago con `estado: "pendiente"` para todos los métodos actuales, incluyendo efectivo. Crear el pedido **no equivale a pago exitoso, confirmación de cocina ni asignación de repartidor**. No ocultar esta condición en la UI ni mostrar un mensaje de “pedido confirmado” solo porque el `POST` haya respondido `201`.

## 3. Consultar estado e historial del cliente

- `GET /pedidos/mios`: lista los pedidos del usuario cliente autenticado, incluyendo items y pago.
- `GET /pedidos/:id`: devuelve el detalle únicamente si pertenece al cliente autenticado (o el usuario tiene rol administrativo autorizado). Si no existe o no pertenece a la cuenta, devuelve `404`.
- Respuesta de consulta incluye las relaciones disponibles: items/agregados, pago, dirección, responsable y atenciones según el endpoint.

Para reanudar una pantalla después de cerrar la app, consultar `GET /pedidos/mios` y recuperar el pedido por su `id`; no depender exclusivamente de notificaciones push o Socket.IO.

## 4. Estados actuales y transiciones

Estados definidos:

| Estado | Interpretación actual |
| --- | --- |
| `PENDIENTE_PAGO` | Pedido creado; el pago figura pendiente. No implica aceptación ni despacho. |
| `CONFIRMADO` | El backend registró pago como pagado mediante el flujo de caja existente. |
| `EN_PREPARACION` | Personal autorizado inició preparación. |
| `EN_CAMINO` | El repartidor asignado inició el tramo de entrega. |
| `ENTREGADO` | Entrega completada. |
| `CANCELADO` | Pedido cancelado por personal autorizado según transición permitida. |

Transiciones de estado previstas por backend: `PENDIENTE_PAGO -> CONFIRMADO/CANCELADO`; `CONFIRMADO -> EN_PREPARACION/CANCELADO`; `EN_PREPARACION -> EN_CAMINO/ENTREGADO/CANCELADO`; `EN_CAMINO -> ENTREGADO/CANCELADO`. Delivery solo puede pasar a `ENTREGADO` desde `EN_CAMINO`. Las reglas de rol restringen más estas transiciones: un repartidor solo puede avanzar su propio pedido asignado de `EN_PREPARACION` a `EN_CAMINO` y luego a `ENTREGADO`.

La app cliente **no** tiene permiso para modificar estados, confirmar pago ni asignar repartidor. No llamar a endpoints administrativos desde móvil.

## 5. Pagos: qué existe y qué falta

El modelo contiene `MetodoPago` (`YAPE`, `EFECTIVO`, `TARJETA`) y una entidad de pago con `pasarela` (`CULQI`, `IZIPAY`), `transactionId`, `monto` y texto `estado`. Sin embargo, en el backend actual:

- No hay endpoint de checkout ni de creación de intento/token de pago para tarjeta.
- No hay integración implementada de Culqi/Izipay ni webhook para verificar una transacción.
- La app cliente no tiene endpoint para marcar un pago como pagado.
- `PATCH /pedidos/:id/confirmar-pago` es una operación de caja protegida para personal con `pedidos:cobrar`; no debe usarse desde la app de cliente.
- El flujo tampoco define aún de forma diferenciada cuándo se cobra una contraentrega (efectivo o POS del repartidor) respecto del pago anticipado por tarjeta/Yape.

Por tanto, no capturar, almacenar ni enviar número de tarjeta, CVV, PIN o credenciales financieras a esta API. Antes de habilitar tarjeta se debe acordar e implementar el proveedor/tokenización, webhooks verificados, idempotencia, estados de pago, expiración/cancelación de intentos y transición del pedido solo tras verificación server-to-server. Para contraentrega, falta definir si el pedido se acepta antes del cobro y cómo registrar el efectivo/POS al entregar.

Hasta que ese backend exista, la app puede preparar UI/selección de método, pero no debe afirmar que cobró tarjeta ni marcar el pedido confirmado. Coordinar el contrato de pago antes de publicar checkout productivo.

## 6. Reparto que existe hoy (principalmente para la app de repartidor)

Perfil y disponibilidad:

- `PATCH /repartidores/ubicacion` (solo `REPARTIDOR`): `{ "lat": -12.0, "lng": -77.0 }`.
- `PATCH /repartidores/disponibilidad` (solo `REPARTIDOR`): `{ "disponible": true }`.
- `PATCH /repartidores/vehiculo` (solo `REPARTIDOR`): `{ "vehiculo": "Moto" }`.
- `GET /pedidos/repartidor/mis-entregas` (solo `REPARTIDOR`): lista hasta 20 entregas asignadas, incluye dirección, cliente, pago e items; no incluye pedidos cancelados.

El backend guarda una última posición, pero no define frecuencia de actualización, retención, consentimiento, permisos en segundo plano, caducidad de posición ni transmisión en tiempo real a clientes. El móvil debe pedir permiso explícito de ubicación y enviar solo cuando el repartidor se encuentre disponible y conforme a la política que acuerde el equipo. La ruta actual recibe coordenadas numéricas; no es aún un canal de tracking en vivo.

Gestión administrativa:

- `GET /repartidores`: lista perfiles.
- `GET /repartidores/disponibles`: devuelve disponibles con ubicación y cupo libre.
- `GET /repartidores/sugerido/:pedidoId`: recomienda candidato para pedido delivery confirmado/en preparación con dirección. La puntuación combina 50% distancia Haversine en línea recta normalizada y 50% carga activa relativa (`pedidosActivos / capacidadPedidos`). Menor puntaje es mejor. No calcula ETA ni ruta vial.
- `PATCH /pedidos/:id/asignar-repartidor` (ADMIN o `PERSONALIZADO` con `reparto:gestion`): body `{ "repartidorId": 12 }`. Es asignación **manual**. El pedido debe ser `DELIVERY`, `CONFIRMADO` o `EN_PREPARACION` y todavía no estar asignado; el repartidor debe estar disponible y debajo de su capacidad. El límite se configura desde Gestión de Usuarios; valor por defecto 2.
- `PATCH /pedidos/:id/estado` con `{ "estado": "EN_CAMINO" }` o `{ "estado": "ENTREGADO" }`: para repartidor autenticado solo funciona con un pedido que le fue asignado y transiciones válidas.

No hay asignación automática al crear o pagar pedido. La sugerencia no reserva capacidad; la operación de asignar es la que vuelve a validar disponibilidad/cupo dentro de una transacción. No hay endpoint móvil de repartidor para aceptar/rechazar asignación o para obtener pedidos disponibles sin asignar.

## 7. Tiempo real disponible y límites

Socket.IO corre en el mismo host HTTP. Conectar enviando el JWT así:

```js
io(API_ORIGIN, { auth: { token } });
```

Eventos existentes:

- `pedido:nuevo`: se emite a la sala administrativa al crear pedido; el cliente móvil no recibe este evento.
- `pedido:actualizado`: se emite a administración y a suscriptores autorizados a la sala del pedido.
- `producto:disponibilidad`: cambio de disponibilidad del menú.

Un cliente autenticado puede solicitar seguimiento de un pedido propio:

```js
socket.emit("pedido:seguir", pedidoId);
socket.on("pedido:actualizado", pedido => { /* actualizar UI */ });
```

Solo se une a la sala del pedido si es dueño del pedido; validar siempre con REST al iniciar/reconectar y tratar el socket como acelerador de actualización, no como fuente persistente. Actualmente `pedido:actualizado` puede llevar solo el objeto devuelto por la operación que cambió el pedido (no siempre trae todas las relaciones); volver a consultar `GET /pedidos/:id` al recibirlo si la UI necesita detalle completo.

No hay eventos Socket.IO de posición de repartidor, ETA, repartidor cercano, pago, ni notificaciones push/APNs/FCM. El namespace no autoriza al repartidor a seguir una sala de pedido por `pedido:seguir`. Esas funciones requieren implementación backend y contrato de permisos antes de que la app dependa de ellas.

## 8. Contrato que conviene acordar para completar checkout móvil

Antes de activar el flujo de compra público, cliente móvil y backend deben definir conjuntamente:

1. Métodos y textos de pago que verá el cliente: tarjeta anticipada, efectivo al recibir, POS al recibir y si Yape se conserva.
2. Cuándo se acepta el pedido y qué se muestra durante el pago; política de fallos, abandono, reintentos, idempotencia y cancelación.
3. Si se toma el pedido para cocina al crearlo o solo tras pago/aceptación, y cómo evitar duplicados al reintentar una solicitud.
4. Momento de asignación automática: normalmente después de que el pedido sea aceptado y exista dirección válida; confirmar política para contraentrega y falta de repartidores/cupo.
5. Restricción de cobertura: zonas/radio atendidos y validación server-side de dirección.
6. Forma de tracking: polling o evento autenticado, frecuencia, ubicación solo durante entrega activa, caducidad y consentimiento.
7. Proveedor de mapas/rutas y origen del ETA. La distancia Haversine actual solo sirve para ordenar candidatos, no representa distancia por calles ni tiempo.
8. Notificaciones push y eventos durables para cambios aunque la app esté cerrada.

Sugerencia de evolución de API (propuesta, **no implementada**): crear checkout/pedido idempotente, iniciar pago con proveedor sin datos de tarjeta en el servidor de la app, verificar resultado mediante webhook, aceptar pedido, despachar usando el balanceador actual y publicar actualizaciones de estado/ubicación a clientes autorizados. El contrato final debe versionarse/documentarse antes de consumo por el móvil.

## 9. Preparación del entorno y migraciones

Antes de probar contra el backend desplegado, verificar que las migraciones están aplicadas. Para el código actual son necesarias, en orden, las migraciones de ciudad, subcategorías, área de preparación y capacidad de repartidor, además de las migraciones iniciales del proyecto. La última agregada es `20261003173000_capacidad_pedidos_repartidor`, con valor por defecto `2`.

Comandos a ejecutar desde `Pikza-pizza-backend` cuando el equipo confirme que corresponde desplegarlas:

```powershell
npx prisma migrate status
npx prisma migrate deploy
npx prisma generate
```

No se ejecutó `migrate deploy` ni se modificó la base remota al preparar este documento. Si Prisma detecta una migración fallida o divergencia, detenerse y revisar el estado antes de reintentar; no borrar filas de `_prisma_migrations` ni carpetas de migración para forzar el deploy.

## 10. Checklist de integración para QA móvil

- [ ] Inicio de sesión conserva el token de forma segura y lo renueva/rechaza ante `401`.
- [ ] Menú oculta productos/variantes no disponibles y usa los IDs de backend.
- [ ] Dirección seleccionada persiste `direccionId` y coordenadas reales.
- [ ] El total en UI se recalcula como estimación, pero se reemplaza por el total autoritativo de la respuesta.
- [ ] El carrito maneja errores `400`, `403`, `404`, `409` y falta de conectividad sin mostrar éxito falso.
- [ ] Tras crear pedido se presenta el estado devuelto (hoy: pendiente de pago), no un pago confirmado.
- [ ] La pantalla de pedido obtiene estado persistente por REST y, si usa Socket.IO, se suscribe a pedido propio y vuelve a consultar después de reconexión/evento.
- [ ] La app móvil no invoca rutas de caja, administración, asignación manual ni cambio de estado de repartidor.
- [ ] No se recopilan ni transmiten datos crudos de tarjeta.
- [ ] Validar el flujo con un pedido de prueba y base de pruebas con migraciones aplicadas antes de habilitar a clientes reales.

## 11. Pendientes backend para integración completa

- Checkout cliente con idempotencia y reglas de pago explícitas.
- Pasarela de tarjeta y webhooks autenticados; flujo POS/efectivo contraentrega.
- Confirmación/aceptación de pedido y política de cancelación.
- Asignación automática al momento acordado, manejando ausencia de candidatos/cupo.
- Registro de posición con fecha de actualización y reglas de privacidad; publicación segura de seguimiento solo al cliente dueño y repartidor asignado.
- ETA/ruta vial mediante proveedor acordado (no usar Haversine como ETA).
- Push y/o mecanismo de entrega durable cuando la app esté cerrada.
- Pruebas de integración para pagos, concurrencia de asignación y permisos de seguimiento.
