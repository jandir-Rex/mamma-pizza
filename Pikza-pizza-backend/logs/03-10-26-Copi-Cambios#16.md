# [PEDIDOS] [RESPONSIVE] [TABLET] [MOVIL]

## Cambios

- En pantallas menores a 1024 px, la creación de pedidos ocupa la pantalla completa en lugar de comprimir catálogo y comanda en dos columnas.
- El catálogo se muestra primero y una barra fija inferior permite revisar cantidad de productos y total.
- La vista del pedido permite volver al catálogo sin perder productos, cantidades ni notas.
- En pantallas amplias se conserva el diseño de catálogo y comanda lado a lado.
- Se bloquea el desplazamiento de la página de fondo mientras se crea el pedido; Escape permite cerrar la vista.

## Verificación

- Pasó `npm run build` del frontend.
- Pasó ESLint de `DrawerCrearPedido.tsx`.
- Build conserva el aviso preexistente sobre el tamaño del bundle JavaScript (>500 kB).
