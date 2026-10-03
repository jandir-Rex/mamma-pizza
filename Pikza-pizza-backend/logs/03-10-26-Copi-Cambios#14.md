# [PERFIL] [DOMICILIO] [PERSISTENCIA] [MIGRACION]

## Hallazgo

- `UserAddressCard` enviaba DNI y dirección a `PATCH /auth/perfil`, pero `actualizarPerfilSchema` no aceptaba esos campos. Zod los eliminaba antes de que llegaran al servicio.
- Ciudad solo se mantenía en estado local del formulario: no se enviaba, no estaba en el modelo Prisma y la tarjeta no cargaba los datos guardados desde el servidor.

## Cambios

- Se aceptan y persisten DNI, dirección y ciudad; enviar un campo vacío permite borrarlo de la cuenta.
- Se agregó la columna opcional `usuarios.ciudad` mediante migración `20261003161800_usuario_ciudad`.
- La sesión devuelve los datos de perfil para cargarlos al abrir la sección y el formulario actualiza la tarjeta con la respuesta persistida.
- Se documentó el endpoint y la migración.

## Verificación

- `npm run build` y ESLint del componente de perfil pasaron.
- `node --check` de los módulos de autenticación pasó.
- La validación Zod comprobó los tres campos y el envío explícito de valores vacíos para borrarlos.
- `prisma validate` confirmó que el esquema es válido y se regeneró Prisma Client.
- La migración no se aplicó a una base real durante esta verificación.
