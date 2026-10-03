# [ANALITICAS] [AUDITORIA] [PAGINACION] [FILTROS]

## Resumen

- La auditoría de órdenes ahora usa `GET /pedidos/auditoria` y pagina en backend, con tamaños permitidos de 10, 20 y 50.
- Se añadieron filtros combinables por búsqueda de código/cliente, estado del pedido, canal, estado de pago y usuario que registró originalmente la orden.
- Se conserva la seguridad de canales para personal con `pedidos:ver`; las opciones de iniciador se limitan al usuario propio en respuestas no administrativas.
- La respuesta incluye total, página, tamaño, páginas disponibles y opciones de personal.
- Los indicadores de analítica se calculan mediante `GET /pedidos/resumen` con agregaciones en base de datos; la página ya no necesita descargar todos los pedidos del periodo para sumar ventas y canales.
- Se actualizaron los README de backend y frontend.

## Verificación

- Pasaron `node --check` para validación, controlador, rutas y servicio.
- Pasaron pruebas de validación de filtros y límites, paginación/filtros del servicio con Prisma simulado y agregados por canal/ventas.
- ESLint de la página de analíticas pasó.
- `npm run build` pasa.
- Vite mantiene su aviso existente de bundle superior a 500 kB.
