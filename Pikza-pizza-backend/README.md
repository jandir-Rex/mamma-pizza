# Mamma Pizza Backend

API REST y servidor Socket.IO para los pedidos, el menú, las mesas y las entregas de Mamma Pizza. La API persiste los datos en PostgreSQL mediante Prisma y aplica autenticación JWT y permisos por rol.

## Tecnologías

- Node.js 22 o superior y Express 5
- PostgreSQL y Prisma ORM 7
- JWT para autenticación; roles disponibles: `CLIENTE`, `ADMIN`, `MOZO`, `REPARTIDOR` y `PERSONALIZADO`
- Zod para validar datos de entrada
- Socket.IO para notificaciones de pedidos y disponibilidad de productos

## Requisitos

- Node.js 22 o superior y npm
- Acceso a una base de datos PostgreSQL
- Valores propios para `DATABASE_URL` y `JWT_SECRET`

## Configuración local

Desde la raíz del repositorio:

```powershell
cd mamma-pizza-backend
npm ci
Copy-Item .env.example .env
```

Edita `.env` y configura `DATABASE_URL`, `JWT_SECRET` y, opcionalmente, `PORT` (por defecto `4000`). Usa credenciales proporcionadas por el equipo y un secreto JWT aleatorio. No reutilices los valores que actualmente aparecen en `.env.example`; ese archivo debe reemplazarse por placeholders y las credenciales expuestas deben rotarse.

Genera el cliente de Prisma y aplica las migraciones pendientes:

```powershell
npx prisma generate
npx prisma migrate deploy
```

Inicia el servidor:

```powershell
npm run dev
```

Para ejecutarlo sin modo desarrollo:

```powershell
npm start
```

La API queda disponible en `http://localhost:4000/api`. Comprueba el estado en `GET /api/health`.

## API disponible

Todas las rutas están bajo `/api`. Las rutas marcadas como protegidas requieren `Authorization: Bearer <token>`.

| Módulo | Rutas | Acceso y función |
| --- | --- | --- |
| Salud | `GET /health` | Pública; comprueba que el servidor responde. |
| Autenticación | `POST /auth/registro`, `POST /auth/login` | Registro de clientes e inicio de sesión. El login tiene limitación de solicitudes. |
| Personal | `POST /auth/staff`, `PATCH /auth/perfil`, `GET /auth/sesion` | `ADMIN` puede crear personal; `PERSONALIZADO` puede hacerlo con `usuarios:admin`, sin crear Administradores. Actualizar perfil: usuario autenticado; admite nombre, teléfono, DNI, dirección y ciudad, y devuelve los datos persistidos. `GET /auth/sesion` devuelve el rol/permisos vigentes y los datos de DNI, dirección y ciudad para cargar el perfil. |
| Permisos del personal | `POST /auth/staff`, `PUT /auth/usuarios/:id` | `ADMIN` recibe `*`. Para `MOZO`, `ADMIN` configura lectura, registro/continuación, cobro/finalización y canales. Para `PERSONALIZADO`, `ADMIN` puede configurar permisos independientes de pedidos, mesas, catálogo, repartidores y usuarios; la API valida cada módulo. Quien tenga `usuarios:admin` no puede modificar/eliminar cuentas ADMIN ni asignar permisos superiores a los propios. `REPARTIDOR` no recibe permisos de pedidos. |
| Productos | `GET /productos/menu`, `GET /productos/categorias`, `GET /productos/:id` | Consultar el menú y sus categorías. Las categorías pueden tener subcategorías de un solo nivel; los productos pueden asignarse a una subcategoría o quedarse directamente en su categoría principal. El menú devuelve el área efectiva de preparación de cada producto. |
| Administración de productos | `POST /productos/categorias`, `PATCH /productos/categorias/:id`, `POST /productos`, `PUT /productos/:id`, `DELETE /productos/:id`, `PATCH /productos/variantes/:id/disponibilidad` | `ADMIN` o `PERSONALIZADO` con `productos:admin`; crear categorías principales o subcategorías con `parentId`, configurar áreas de preparación `HORNO` o `BARRA` (subcategorías pueden heredar), crear/editar productos, desactivar productos y cambiar disponibilidad de variantes. |
| Pedidos | `POST /pedidos`, `GET /pedidos`, `GET /pedidos/historial`, `GET /pedidos/auditoria`, `GET /pedidos/resumen`, `GET /pedidos/:id`, `GET /pedidos/mios`, `GET /pedidos/repartidor/mis-entregas` | Crear pedidos: `CLIENTE`, `ADMIN` o personal con permiso de registro para el canal. Listados y consultas por ID del personal se restringen a sus canales asignados. `Para llevar` se identifica como pedido `SALON` sin mesa. Pedidos propios: `CLIENTE`; entregas asignadas: `REPARTIDOR`. `GET /pedidos/historial` acepta el rango opcional `desde` y `hasta`: `ADMIN` ve todos los pedidos del día; `MOZO` y `PERSONALIZADO` con `pedidos:ver` solo pedidos que registraron o continuaron (respetando canales); `REPARTIDOR` solo los pedidos actualmente asignados. `GET /pedidos` admite el rango opcional `desde` y `hasta`. Auditoría: solo devuelve una página (10, 20 o 50) y admite rango, búsqueda, estado, canal, estado de pago e iniciador; responde total, páginas y opciones de personal, y respeta canales permitidos. Resumen: `ADMIN`, devuelve agregados del periodo sin transferir todos los pedidos. |
| Gestión de pedidos | `POST /pedidos/:id/items`, `PATCH /pedidos/:id/confirmar-pago`, `PATCH /pedidos/:id/estado`, `PATCH /pedidos/:id/asignar-repartidor` | Al agregar consumos, `ADMIN`, `MOZO` o `PERSONALIZADO` autorizado pasa a ser responsable actual y se registra el evento. `pedidos:cobrar` permite registrar el pago y finalizar pedidos pagados del canal autorizado; no permite cancelar ni cambiar otros estados. Las finalizaciones operativas guardan qué usuario las realizó. La asignación manual valida disponibilidad y cupo dentro de una transacción; la disponibilidad se pausa por el repartidor y ya no cambia automáticamente por tener un pedido activo. |
| Rendimiento | `GET /pedidos/rendimiento` | Requiere `pedidos:ver`. `ADMIN` obtiene el resumen del equipo; `MOZO` y `PERSONALIZADO` obtienen únicamente sus registros, continuaciones, finalizaciones y picos de actividad. Acepta los mismos parámetros opcionales `desde` y `hasta` que el listado de pedidos. |
| Mesas | `GET /mesas`, `GET /mesas/estado`, `GET /mesas/:id` | Lectura para `ADMIN` y `MOZO`; `PERSONALIZADO` requiere `mesas:ver`. |
| Administración de mesas | `POST /mesas`, `PUT /mesas/:id`, `DELETE /mesas/:id` | `ADMIN` o `PERSONALIZADO` con `mesas:admin`. |
| Repartidores | `GET /repartidores`, `GET /repartidores/disponibles`, `GET /repartidores/sugerido/:pedidoId` | `ADMIN` o `PERSONALIZADO` con `reparto:gestion`; consultar repartidores con capacidad, candidatos online que aún tienen cupo y una sugerencia híbrida ponderada por igual entre carga relativa y distancia en línea recta. La sugerencia retorna distancia, pedidos activos, capacidad y puntaje de balance (menor es mejor); no es asignación automática ni ETA vial. |
| Perfil de repartidor | `PATCH /repartidores/ubicacion`, `PATCH /repartidores/disponibilidad`, `PATCH /repartidores/vehiculo` | Solo `REPARTIDOR`; actualizar su propia información. |
| Agregados | `GET /agregados` | Listar agregados disponibles. |
| Administración de agregados | `POST /agregados`, `PUT /agregados/:id`, `PATCH /agregados/:id/precio` | `ADMIN` o `PERSONALIZADO` con `productos:admin`; crear y editar agregados, o modificar precios por tamaño. |
| Gestión de usuarios | `GET /auth/usuarios`, `POST /auth/staff`, `PUT /auth/usuarios/:id`, `DELETE /auth/usuarios/:id` | `ADMIN` o `PERSONALIZADO` con `usuarios:admin`. El rol configurable no puede modificar/eliminar cuentas ADMIN, crear Administradores o conceder permisos que él mismo no tenga. Para repartidores se configura por usuario la capacidad máxima de pedidos activos (por defecto 2); no se puede reducir por debajo de su carga actual. |
| Direcciones | `POST /direcciones`, `GET /direcciones`, `DELETE /direcciones/:id` | Solo `CLIENTE`; gestionar sus propias direcciones. |

Las rutas de escritura validan sus datos y responden con un error HTTP cuando la solicitud no es válida o el usuario no tiene permisos. La API no ofrece actualmente rutas específicas de reportes, métricas ni de renombrado/eliminación de categorías; la ruta `PATCH /productos/categorias/:id` solo actualiza el área de preparación.

La migración `20261003150000_rol_personalizado` añade `PERSONALIZADO` al enum `RolUsuario`; `20261003161800_usuario_ciudad` agrega el campo `ciudad` al perfil; `20261003170000_categoria_subcategorias` agrega la relación opcional entre una categoría principal y sus subcategorías; `20261003171500_categoria_area_preparacion` habilita clasificar categorías para `HORNO` o `BARRA`; `20261003173000_capacidad_pedidos_repartidor` agrega capacidad activa por repartidor, con valor inicial 2. Aplica las migraciones pendientes y regenera Prisma Client. Los endpoints protegidos consultan los permisos vigentes en base de datos; el panel sincroniza los cambios al recibir la notificación de sesión, al volver a enfocarse o como máximo cada 30 segundos.

La asignación automática aún no está activada: primero debe integrarse el flujo de checkout y el tratamiento distinto de tarjeta/contraentrega, y decidir en qué transición confirmada se despacha el pedido. No existe todavía ETA por calles, seguimiento del cliente ni notificaciones push.

## Eventos en tiempo real

Socket.IO se sirve desde el mismo servidor HTTP y autentica la conexión con el JWT enviado en `auth.token`. Emite estos eventos:

- `pedido:nuevo`: nuevo pedido para el canal de administración.
- `pedido:actualizado`: actualización para administración y suscriptores del pedido.
- `producto:disponibilidad`: cambio de disponibilidad de una variante.

Los clientes pueden solicitar seguimiento con `pedido:seguir`. Administración puede seguir cualquier pedido; un cliente solo puede seguir uno propio.

## Estructura principal

```text
src/
  app.js                 # Registro de rutas y middleware global
  config/                # Variables de entorno y conexión Prisma
  middlewares/           # Autenticación, roles, límites y errores
  modules/               # auth, productos, pedidos, mesas, repartidores,
                         # agregados y direcciones
  sockets/               # Autenticación y eventos Socket.IO
  utils/                 # Utilidades compartidas
prisma/
  schema.prisma          # Modelo de datos
  migrations/            # Migraciones de la base de datos
```

Después de aplicar la migración `20261003130000_pedido_atencion_canales_mozo`, los mozos existentes con permisos de pedidos reciben acceso al canal de salón. Las cuentas con una sesión abierta deben volver a iniciar sesión para cargar sus permisos actualizados.