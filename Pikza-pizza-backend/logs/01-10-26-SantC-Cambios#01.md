# Registro de Cambios y Evolución del Backend (Mamma Pizza)

Este documento detalla todas las modificaciones realizadas sobre el código original del backend para habilitar el control de permisos granulares, la edición completa del catálogo, las comandas vivas en salón, la modalidad "Para Llevar" y la administración integral de usuarios.

---

## Resumen de Archivos Modificados (11 Archivos)

| # | Archivo | Módulo / Área | Tipo de Cambio |
| :- | :--- | :--- | :--- |
| 1 | `prisma/schema.prisma` | Base de Datos | Nuevo campo `permisos` en `Usuario` |
| 2 | `src/middlewares/role.middleware.js` | Middlewares | Soporte de validación por permisos y roles |
| 3 | `src/modules/productos/productos.validation.js` | Productos | Validación de variantes/precios al editar |
| 4 | `src/modules/productos/productos.service.js` | Productos | Transacción para editar precios y crear tamaños |
| 5 | `src/modules/pedidos/pedidos.validation.js` | Pedidos | Soporte "Para Llevar" y validación de comanda viva |
| 6 | `src/modules/pedidos/pedidos.service.js` | Pedidos | Lógica de `agregarItemsAPedido` y mesa opcional |
| 7 | `src/modules/pedidos/pedidos.controller.js` | Pedidos | Controlador `agregarItems` |
| 8 | `src/modules/pedidos/pedidos.routes.js` | Pedidos | Ruta `POST /:id/items` y acceso para `MOZO` |
| 9 | `src/modules/auth/auth.validation.js` | Auth / Usuarios | Esquemas para permisos y edición por Admin |
| 10| `src/modules/auth/auth.service.js` | Auth / Usuarios | CRUD de usuarios, direcciones, conteo y JWT con permisos |
| 11| `src/modules/auth/auth.controller.js` y `auth.routes.js` | Auth / Usuarios | Endpoints `GET`, `PUT` y `DELETE` para `/usuarios` |

---

## Detalle Módulo por Módulo

### 1. Base de Datos (`prisma/schema.prisma`)
* **Estado Original:** El modelo `Usuario` solo manejaba un enum fijo `rol` (`CLIENTE`, `ADMIN`, `REPARTIDOR`, `MOZO`).
* **Modificación:** Se añadió la columna `permisos String[] @default([])` al modelo `Usuario`.
* **Impacto:** Permite almacenar arreglos nativos en PostgreSQL con los permisos específicos de cada trabajador (ej. `["pedidos:ver", "pedidos:crear"]`) sin necesidad de tablas pivote adicionales.

---

### 2. Middleware de Autorización (`src/middlewares/role.middleware.js`)
* **Estado Original:** Solo exportaba la función `permitirRoles(...rolesPermitidos)`.
* **Modificación:**
  * Se agregó la función `permitirPermisos(...permisosRequeridos)` donde el rol `ADMIN` tiene pase libre automático y para el resto del staff se verifica su arreglo de permisos.
  * Se mantuvo la exportación por defecto compatible (`permitirRoles.permitirPermisos = permitirPermisos`) para no romper ningún `require()` existente en los demás módulos.

---

### 3. Módulo de Productos (`src/modules/productos/`)

#### A. `productos.validation.js`
* **Estado Original:** `actualizarProductoSchema` solo permitía actualizar datos planos (`nombre`, `descripcion`, `categoriaId`, `imagenUrl`, `disponible`). Ignoraba cualquier cambio de precios o tamaños.
* **Modificación:** Se creó `varianteUpdateSchema` y se incorporó el arreglo `variantes` dentro de `actualizarProductoSchema`.

#### B. `productos.service.js`
* **Estado Original:** `actualizarProducto` ejecutaba un `prisma.producto.update` simple.
* **Modificación:** Se implementó una transacción (`prisma.$transaction`) que recorre las variantes enviadas:
  * Si la variante ya tiene `id`, actualiza su `tamano` y `precio` (evitando errores de llave foránea con pedidos antiguos).
  * Si no tiene `id`, crea el nuevo tamaño asociado al producto.

---

### 4. Módulo de Pedidos (`src/modules/pedidos/`)

#### A. `pedidos.validation.js`
* **Estado Original:** `crearPedidoSchema` obligaba mediante `.refine()` a que todo pedido con `canal === "SALON"` tuviera un `mesaId` numérico obligatorio, impidiendo registrar pedidos "Para Llevar".
* **Modificación:**
  * Se permitió `mesaId` como opcional/nullable cuando el canal es `SALON`.
  * Se añadió el campo opcional `clienteNombre`.
  * Se creó `agregarItemsSchema` para validar los nuevos productos que se anexan a un pedido abierto.

#### B. `pedidos.service.js`
* **Estado Original:**
  * Validaba la existencia de la mesa siempre que el canal fuera `SALON`.
  * No contaba con lógica para modificar o anexar productos a un pedido existente.
* **Modificación:**
  * Se cambió la validación de mesa a `if (canal === "SALON" && mesaId)` para soportar pedidos de mostrador / para llevar.
  * Se creó la función `agregarItemsAPedido(pedidoId, items)`:
    1. Verifica que el pedido exista y no esté `ENTREGADO` ni `CANCELADO`.
    2. Consulta el precio vigente y disponibilidad de las variantes con bloqueo `FOR UPDATE`.
    3. Inserta los nuevos registros en `pedido_items`.
    4. Suma el nuevo consumo al `subtotal`, `total` y al monto de la tabla `pagos`.
    5. Emite el evento en tiempo real por WebSockets (`emitPedidoActualizado`).

#### C. `pedidos.controller.js` y `pedidos.routes.js`
* **Estado Original:** No existía ruta para anexar productos y la consulta de pedidos (`GET /`) estaba restringida solo a `ADMIN`.
* **Modificación:**
  * Se creó el controlador `agregarItems` y la ruta `POST /api/pedidos/:id/items` para `ADMIN` y `MOZO`.
  * Se habilitó el rol `MOZO` en `GET /api/pedidos` y en `PATCH /api/pedidos/:id/confirmar-pago`.

---

### 5. Módulo de Autenticación y Usuarios (`src/modules/auth/`)

#### A. `auth.validation.js`
* **Estado Original:** `staffSchema` no aceptaba `permisos` y no existía esquema para que el administrador editara cuentas de terceros.
* **Modificación:**
  * Se añadió `permisos: z.array(z.string()).optional()` a `staffSchema`.
  * Se creó `actualizarUsuarioAdminSchema` permitiendo actualizar nombre, email, teléfono, rol, permisos y resetear contraseña.

#### B. `auth.service.js`
* **Estado Original:** Solo permitía registrar clientes, crear staff a ciegas, iniciar sesión y editar el perfil propio.
* **Modificación:**
  * `generarRespuesta`: Ahora incluye el arreglo `permisos` tanto en el payload del token JWT como en el objeto `usuario` devuelto al frontend.
  * `crearStaff`: Guarda los `permisos` asignados (o `["*"]` si es `ADMIN`).
  * **Nueva función `listarUsuarios`**: Devuelve todos los usuarios ordenados por fecha de creación, incluyendo sus `direcciones` registradas desde la app móvil y el conteo total de `pedidos` realizados (`_count`), omitiendo el `passwordHash`.
  * **Nueva función `actualizarUsuarioPorAdmin`**: Permite al administrador editar datos de cualquier usuario, cambiar permisos y encriptar una nueva contraseña si se envía. Incluye protección para impedir que el Admin se quite el rol a sí mismo.
  * **Nueva función `eliminarUsuario`**: Elimina un usuario de la base de datos, impidiendo que el Admin en sesión borre su propia cuenta.

#### C. `auth.controller.js` y `auth.routes.js`
* **Estado Original:** Solo existían las rutas `POST /registro`, `POST /login`, `POST /staff` y `PATCH /perfil`.
* **Modificación:** Se agregaron los controladores y las rutas protegidas para el Administrador:
  * `GET /api/auth/usuarios` (Listar personal y clientes con direcciones).
  * `PUT /api/auth/usuarios/:id` (Modificar usuario / resetear clave).
  * `DELETE /api/auth/usuarios/:id` (Eliminar cuenta).