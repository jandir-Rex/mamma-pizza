-- CreateEnum
CREATE TYPE "EstadoComprobante" AS ENUM ('SIN_COMPROBANTE', 'EN_REVISION', 'APROBADO', 'RECHAZADO');

-- AlterTable
ALTER TABLE "pagos" ADD COLUMN     "comprobanteEstado" "EstadoComprobante" NOT NULL DEFAULT 'SIN_COMPROBANTE',
ADD COLUMN     "comprobanteMotivo" TEXT,
ADD COLUMN     "comprobanteSubidoEn" TIMESTAMP(3),
ADD COLUMN     "pagaCon" DECIMAL(10,2),
ADD COLUMN     "yapeNombre" TEXT;

-- AlterTable
ALTER TABLE "pedidos" ADD COLUMN     "disculpaEnviadaEn" TIMESTAMP(3);

-- CreateTable
CREATE TABLE "pago_comprobantes" (
    "id" SERIAL NOT NULL,
    "pagoId" INTEGER NOT NULL,
    "mime" TEXT NOT NULL,
    "datos" BYTEA NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "pago_comprobantes_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "pago_comprobantes_pagoId_key" ON "pago_comprobantes"("pagoId");

-- AddForeignKey
ALTER TABLE "pago_comprobantes" ADD CONSTRAINT "pago_comprobantes_pagoId_fkey" FOREIGN KEY ("pagoId") REFERENCES "pagos"("id") ON DELETE CASCADE ON UPDATE CASCADE;
