# [PEDIDOS] [IMPRESION] [HORNO] [BARRA] [CATEGORIAS]

## Cambios

- Se agregaron áreas de preparación `HORNO` y `BARRA` a la configuración de categorías.
- Las subcategorías pueden heredar el área de la categoría principal o sobrescribirla.
- El drawer de categorías permite asignar y cambiar el área de cada categoría/subcategoría.
- El detalle de pedido ahora imprime tickets de preparación separados por área presente en el pedido, en un mismo trabajo de impresión.
- Los tickets identifican el área, pedido, mesa/canal, responsable, cliente, productos y notas; dejan de depender de excepciones por nombre de bebida.
- Las precuentas conservan su impresión de precios y totales.
- Se agregó la migración `20261003171500_categoria_area_preparacion`; no se aplicó a la base de datos.
- Se actualizó el README del backend.

## Verificación

- Pasaron `npx prisma validate` y `npx prisma generate`.
- Pasaron `npm run build`, ESLint de los componentes implicados y `node --check` en rutas/controlador/servicio/validación de productos.
- La migración no se aplicó a la base de datos; deben aplicarse las migraciones pendientes en orden antes de usar la nueva columna.
- El build conserva el aviso existente sobre el tamaño del bundle JavaScript (>500 kB).
