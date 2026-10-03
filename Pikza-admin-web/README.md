# Mamma Pizza Admin Web

Panel web para la operación diaria de Mamma Pizza. Se conecta a la API del backend; no accede directamente a la base de datos.

## Tecnologías

- React 19 y TypeScript
- Vite 8
- Tailwind CSS 4
- React Router
- Socket.IO Client

## Requisitos

- Node.js 20.19 o superior (o 22.12 o superior)
- pnpm
- Backend de Mamma Pizza disponible y credenciales válidas para iniciar sesión

## Configuración local

Desde la raíz del repositorio:

```powershell
cd mamma-pizza-admin-web
pnpm install
```

Opcionalmente, crea `.env.local` para cambiar la dirección del backend:

```dotenv
VITE_API_URL=http://localhost:4000/api
VITE_SOCKET_URL=http://localhost:4000
```

Por defecto, las mismas direcciones locales se usan aunque no exista `.env.local`. `VITE_API_URL` define la base de la API; `VITE_SOCKET_URL` permite definir por separado el servidor Socket.IO. Las variables `VITE_*` son públicas y no deben contener secretos.

Inicia el servidor de desarrollo:

```powershell
pnpm dev
```

Vite muestra en la terminal la dirección local, normalmente `http://localhost:5173`.

## Scripts

```powershell
pnpm dev       # Servidor de desarrollo
pnpm build     # Comprobación TypeScript y build de producción
pnpm lint      # ESLint
pnpm preview   # Previsualizar el build local
```

## Acceso y pantallas

El panel acepta los roles `ADMIN` y `REPARTIDOR`; los demás roles no pueden iniciar sesión aquí. Las rutas protegidas redirigen según el rol:

| Ruta | Rol | Función |
| --- | --- | --- |
| `/login` | Público | Inicio de sesión del personal. |
| `/admin` | `ADMIN` | Resumen de pedidos del día e indicadores calculados en el cliente. |
| `/admin/pedidos` | `ADMIN` | Pedidos de hoy, filtros por estado y código, actualización manual, detalle, confirmación de pago, cambio de estado y asignación de repartidor. |
| `/admin/historial` | `ADMIN` y personal con permiso `pedidos:ver` | Consulta por fecha, búsqueda por código o cliente y detalle de solo lectura. El personal ve únicamente pedidos que registró o continuó, limitado a sus canales. |
| `/repartidor/historial` | `REPARTIDOR` | Consulta por fecha y búsqueda de los pedidos que tiene asignados, con detalle de solo lectura. |
| `/admin/analiticas` | `ADMIN` y personal con permiso `pedidos:ver` | Métricas y rendimiento; el personal ve solo sus datos. La auditoría paginada con filtros está disponible únicamente para `ADMIN`. |
| `/repartidor` | `REPARTIDOR` | Entregas asignadas y avance de estado de preparación a en camino y entregado. |
| `/pedidos` | `ADMIN` | Alias de `/admin/pedidos`. |

El historial inicia mostrando el día actual. El registro operativo consulta los pedidos de hoy e incluye los pendientes de pago para que puedan procesarse. La auditoría carga páginas de 10, 20 o 50 pedidos desde el backend; los agregados de analítica se consultan sin descargar toda la lista de pedidos.

## Integración con el backend

Las solicitudes HTTP pasan por `src/services/api.ts`, que agrega el token JWT y usa `VITE_API_URL` (por defecto `http://localhost:4000/api`). El cliente Socket.IO se conecta después del login usando el token y `VITE_SOCKET_URL` o el origen de la API si no se configura. La conexión está preparada, pero las páginas aún no consumen eventos en tiempo real.

El backend también ofrece endpoints de productos, categorías, agregados, mesas y administración de personal. Este frontend aún no tiene pantallas para gestionar esos recursos.

## Estructura principal

```text
src/
  App.tsx                    # Rutas y protección por rol
  components/                # Componentes compartidos y pedidos
  context/                   # Sesión y autenticación
  layout/                    # Estructura del panel
  pages/Administracion/      # Dashboard, pedidos, historial y delivery
  services/                  # Cliente API, caché de pedidos y Socket.IO
  types/                     # Tipos compartidos del frontend
```