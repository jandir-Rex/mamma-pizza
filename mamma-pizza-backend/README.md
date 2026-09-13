# Mamma Pizza — Backend

API REST del sistema de pedidos, delivery y gestión en tiempo real de Mamma Pizza (Trujillo).

## Stack

- Node.js 22 + Express
- PostgreSQL (Neon) + Prisma ORM
- JWT para autenticación por roles (CLIENTE, ADMIN, REPARTIDOR)
- Zod para validación

## Requisitos previos

- **Node.js v22 o superior** (recomendado usar [nvm](https://github.com/coreybutler/nvm-windows) si tienes otra versión instalada)
- Git
- El connection string de la base de datos (pídelo al equipo, no está en este repo por seguridad)

## Instalación

1. Clona el repo y entra a esta carpeta:
```bash
   git clone https://github.com/jandir-Rex/mamma-pizza.git
   cd mamma-pizza/mamma-pizza-backend
```

2. Instala las dependencias:
```bash
   npm install
```

3. Copia el archivo de ejemplo de variables de entorno:
```bash
   copy .env.example .env
```

4. Abre `.env` y reemplaza `DATABASE_URL` y `JWT_SECRET` con los valores reales (pídeselos al equipo).

5. Genera el cliente de Prisma:
```bash
   npx prisma generate
```

6. Levanta el servidor:
```bash
   npm run dev
```

7. Verifica que funcione entrando a: `http://localhost:4000/api/health`
   Deberías ver: `{"status":"ok","mensaje":"Mamma Pizza API funcionando"}`

## Estructura del proyecto