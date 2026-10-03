const { PrismaClient } = require("@prisma/client");
const { PrismaPg } = require("@prisma/adapter-pg");
require("dotenv").config();

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL });
const prisma = new PrismaClient({ adapter });

async function main() {
    const mesa = await prisma.mesa.upsert({
        where: { numero: 1 },
        update: {},
        create: { numero: 1, capacidad: 4 },
    });

    const direccion = await prisma.direccion.upsert({
        where: { id: 1 },
        update: {},
        create: {
            usuarioId: 1, // el "Juan Perez" que ya registraste
            zona: "Urb. California",
            referencia: "Cerca al parque",
            lat: -8.111,
            lng: -79.028,
        },
    });

    console.log("Mesa creada:", mesa);
    console.log("Dirección creada:", direccion);
}

main()
    .catch(console.error)
    .finally(() => process.exit());