-- CreateTable
CREATE TABLE "config_pago" (
    "id" INTEGER NOT NULL DEFAULT 1,
    "yapeNumero" TEXT,
    "yapeTitular" TEXT,
    "qrMime" TEXT,
    "qrActualizadoEn" TIMESTAMP(3),
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "config_pago_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "config_pago_qr" (
    "id" SERIAL NOT NULL,
    "configId" INTEGER NOT NULL,
    "mime" TEXT NOT NULL,
    "datos" BYTEA NOT NULL,

    CONSTRAINT "config_pago_qr_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "config_pago_qr_configId_key" ON "config_pago_qr"("configId");

-- AddForeignKey
ALTER TABLE "config_pago_qr" ADD CONSTRAINT "config_pago_qr_configId_fkey" FOREIGN KEY ("configId") REFERENCES "config_pago"("id") ON DELETE CASCADE ON UPDATE CASCADE;
