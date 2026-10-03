# [PEDIDOS] [HISTORIAL] [ANALITICAS] [NAVEGACION]

## Resumen

- Las analíticas de rendimiento y reportes se movieron a su propia página y ruta `/admin/analiticas`.
- Se restauró una sección independiente de historial en `/admin/historial`.
- El historial permite seleccionar una fecha, buscar por código o cliente y consultar el detalle del pedido en modo de solo lectura.
- El menú muestra por separado "Historial" y "Analíticas y reportes" a los usuarios con el permiso `pedidos:ver`.
- No se cambiaron permisos backend ni se requieren migraciones.

## Verificación

- ESLint de las páginas, rutas y menú afectados pasó.
- `npm run build` pasó.
- Vite informa que el bundle de entrada supera 500 kB.
