-- CreateTable
CREATE TABLE "agregados" (
    "id" SERIAL NOT NULL,
    "nombre" TEXT NOT NULL,
    "disponible" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "agregados_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "agregado_precios" (
    "id" SERIAL NOT NULL,
    "agregadoId" INTEGER NOT NULL,
    "tamano" TEXT NOT NULL,
    "precio" DECIMAL(10,2) NOT NULL,

    CONSTRAINT "agregado_precios_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pedido_item_agregados" (
    "id" SERIAL NOT NULL,
    "pedidoItemId" INTEGER NOT NULL,
    "agregadoId" INTEGER NOT NULL,
    "precioUnitario" DECIMAL(10,2) NOT NULL,

    CONSTRAINT "pedido_item_agregados_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "agregados_nombre_key" ON "agregados"("nombre");

-- CreateIndex
CREATE UNIQUE INDEX "agregado_precios_agregadoId_tamano_key" ON "agregado_precios"("agregadoId", "tamano");

-- AddForeignKey
ALTER TABLE "agregado_precios" ADD CONSTRAINT "agregado_precios_agregadoId_fkey" FOREIGN KEY ("agregadoId") REFERENCES "agregados"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pedido_item_agregados" ADD CONSTRAINT "pedido_item_agregados_pedidoItemId_fkey" FOREIGN KEY ("pedidoItemId") REFERENCES "pedido_items"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pedido_item_agregados" ADD CONSTRAINT "pedido_item_agregados_agregadoId_fkey" FOREIGN KEY ("agregadoId") REFERENCES "agregados"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
