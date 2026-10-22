-- AlterTable
ALTER TABLE "pedidos" ADD COLUMN     "codigoConfirmacion" TEXT,
ADD COLUMN     "confirmadoEn" TIMESTAMP(3),
ADD COLUMN     "intentosCodigoFallidos" INTEGER NOT NULL DEFAULT 0;
