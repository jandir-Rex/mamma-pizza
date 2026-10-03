# [PEDIDOS] [CATALOGO] [RESPONSIVE] [TARJETAS]

## Cambios

- El catálogo al crear pedidos ahora distribuye las tarjetas en columnas independientes en vez de filas de altura compartida.
- Cada tarjeta mantiene su altura según descripción y variantes, y las tarjetas siguientes aprovechan el espacio disponible.
- En pantallas pequeñas se usa una columna; desde el breakpoint `sm` se muestran dos columnas.
- La vista de lista y la administración del catálogo no cambian.

## Verificación

- Pasó `npm run build` del frontend.
- Pasó ESLint de `DrawerCrearPedido.tsx`.
- Build conserva el aviso existente sobre el tamaño del bundle JavaScript (>500 kB).
