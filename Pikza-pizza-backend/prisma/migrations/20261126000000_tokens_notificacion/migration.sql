CREATE TABLE "instalaciones_notificacion" (
    "id" SERIAL NOT NULL,
    "usuarioId" INTEGER NOT NULL,
    "app" VARCHAR(20) NOT NULL,
    "fid" VARCHAR(128) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "instalaciones_notificacion_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "instalaciones_notificacion_fid_key" ON "instalaciones_notificacion"("fid");

CREATE INDEX "instalaciones_notificacion_usuarioId_app_idx" ON "instalaciones_notificacion"("usuarioId", "app");

ALTER TABLE "instalaciones_notificacion"
ADD CONSTRAINT "instalaciones_notificacion_usuarioId_fkey"
FOREIGN KEY ("usuarioId") REFERENCES "usuarios"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
