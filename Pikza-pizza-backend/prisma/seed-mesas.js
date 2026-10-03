const { PrismaClient } = require("@prisma/client");
const { PrismaPg } = require("@prisma/adapter-pg");
require("dotenv").config();

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL });
const prisma = new PrismaClient({ adapter });

async function main() {
  for (let numero = 1; numero <= 8; numero++) {
    const mesa = await prisma.mesa.upsert({
      where: { numero },
      update: {},
      create: { numero, capacidad: 4 },
    });
    console.log(`Mesa ${mesa.numero} lista (id ${mesa.id})`);
  }
}

main().catch(console.error).finally(() => process.exit());