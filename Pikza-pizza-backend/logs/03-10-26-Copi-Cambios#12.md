# [ANALITICAS] [RENDIMIENTO] [EQUIPO] [DRAWER]

## Resumen

- La tarjeta “Rendimiento del equipo” muestra como máximo las primeras cuatro personas del ranking.
- Cuando hay más de cuatro, aparece “Ver equipo completo” y abre un drawer con la lista completa desplazable.
- Se conserva el orden del ranking y el detalle de comandas registradas, continuadas y finalizadas.

## Verificación

- ESLint de `AnaliticasReportes.tsx` pasó.
- `npm run build` pasó con TypeScript.
- Vite mantiene el aviso existente de bundle superior a 500 kB.
