// limpiar.js
const prisma = require("./src/config/prisma");

async function reactivarTodo() {
  const p = await prisma.producto.updateMany({
    data: { disponible: true },
  });

  const v = await prisma.productoVariante.updateMany({
    data: { disponible: true },
  });

  console.log(`Listo: Se reactivaron ${p.count} productos y ${v.count} tamaños/variantes en la carta.`);
}

reactivarTodo()
  .catch((err) => console.error(err))
  .finally(() => process.exit(0));