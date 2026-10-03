CREATE TYPE "AreaPreparacion" AS ENUM ('HORNO', 'BARRA');

ALTER TABLE "categorias"
ADD COLUMN "areaPreparacion" "AreaPreparacion";
