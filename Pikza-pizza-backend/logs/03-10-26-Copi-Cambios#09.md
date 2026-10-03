# [UI] [DRAWERS] [OVERLAYS] [BLUR]

## Resumen

- Las ventanas servidas por el componente compartido `Modal` ahora usan un panel lateral derecho, full-height, en vez de un diálogo centrado.
- Se mantuvo la API del componente compartido para no obligar a sus consumidores a cambiar su lógica de apertura/cierre.
- Los overlays de drawers y ventanas compartidas cubren el viewport con `fixed inset-0` y utilizan un blur tenue de 2 px.
- Se adaptó el formulario de cambio de contraseña al panel lateral y se mantuvieron sus acciones junto al contenido del formulario.
- Se normalizó el overlay en drawers de pedidos, productos, usuarios y perfil.

## Verificación

- ESLint de todos los componentes modificados pasó.
- `npm run build` pasó.
- El ESLint ampliado que incluye `CalendarEventModal.tsx` detectó un error previo en su efecto de sincronización de estado; no se modificó ese archivo.
- Vite mantiene el aviso existente de bundle mayor a 500 kB.
