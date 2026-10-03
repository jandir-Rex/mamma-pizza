# [PEDIDOS] [ESTADOS] [DELIVERY] [MOZOS]

## Resumen

- El módulo de operaciones ahora muestra únicamente pedidos activos en la pestaña inicial, con contadores de canales que también excluyen pedidos finalizados y cancelados.
- Los pedidos finalizados y cancelados tienen filtros separados para que los anulados no se confundan con pedidos atendidos.
- En salón y para llevar, el estado persistido `ENTREGADO` se presenta como "Finalizado". En delivery conserva "Entregado".
- El cobro de delivery registra el pago, pero no marca la entrega como completada ni libera una mesa.
- El backend solo permite al repartidor asignado iniciar una entrega preparada (`EN_PREPARACION` -> `EN_CAMINO`) y completar una entrega en curso (`EN_CAMINO` -> `ENTREGADO`). El personal de salón no puede finalizar delivery.
- El detalle del historial distingue el evento de finalización de los eventos de registro y continuación.

## Criterio de negocio

- Se conserva el estado interno `ENTREGADO` para evitar una migración de base de datos y no romper integraciones existentes; su etiqueta visible depende del canal.
- Un pago no equivale a una entrega: delivery permanece en su ciclo operativo hasta que el repartidor asignado confirma la entrega.
- Las cancelaciones no se contabilizan como finalizaciones exitosas y permanecen disponibles en un filtro propio.

## Verificación

- No se requieren cambios de esquema ni migraciones.
- `node --check src/modules/pedidos/pedidos.service.js` pasó.
- ESLint de los componentes, tipos y página afectados pasó.
- `vite build` pasó.
- `npm run build` sigue bloqueado por el error previo `UserAddressCard.tsx:16` (`usuario` declarado y no usado), ajeno a este cambio.
