# [PERFIL] [TELEFONO] [VALIDACION]

## Cambios

- El teléfono de contacto acepta solo dígitos y limita la entrada del formulario a 9.
- La API valida que el número tenga exactamente 9 dígitos si se proporciona; también permite dejarlo vacío para quitarlo.
- La sesión carga el teléfono guardado y la tarjeta refleja el valor confirmado por la API al guardar.

## Verificación

- Pasó ESLint del editor de perfil y `npm run build`.
- Se comprobó la validación backend: acepta nueve dígitos o vacío y rechaza longitudes/formato distintos.
- Pasó `node --check` en los módulos de autenticación modificados.
