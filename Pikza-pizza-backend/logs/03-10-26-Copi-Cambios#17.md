# [CATALOGO] [CATEGORIAS] [SUBCATEGORIAS] [PEDIDOS]

## Cambios

- Las categorías principales pueden tener subcategorías compartidas en el catálogo, con un solo nivel de jerarquía.
- El formulario de categorías permite crear una categoría principal o una subcategoría de una categoría existente.
- Al crear o editar productos se puede elegir una subcategoría; dejarla vacía mantiene el producto directamente en la categoría principal.
- El catálogo administrativo y el creador de pedidos filtran por categoría principal y por subcategoría. Seleccionar una categoría principal incluye también sus productos directos y los de sus subcategorías.
- La API incluye la relación de categoría principal y valida que las subcategorías no se aniden.
- Se agregó la migración `20261003170000_categoria_subcategorias`; no se aplicó a la base de datos.
- El README del backend describe el esquema y la migración.

## Verificación

- Pasaron `npx prisma validate` y `npx prisma generate`.
- Pasaron `npm run build` y ESLint de los componentes afectados.
- Pasó la validación de entradas para categorías principales y subcategorías.
- No se aplicó la migración; debe ejecutarse en el entorno de base de datos cuando corresponda.
- El build mantiene el aviso existente sobre el tamaño del bundle JavaScript (>500 kB).
