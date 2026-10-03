ALTER TYPE "RolUsuario" ADD VALUE IF NOT EXISTS 'MOZO';

ALTER TABLE "usuarios"
    ADD COLUMN IF NOT EXISTS "dni" TEXT,
    ADD COLUMN IF NOT EXISTS "direccion" TEXT,
    ADD COLUMN IF NOT EXISTS "permisos" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[];

ALTER TABLE "pedidos"
    ADD COLUMN IF NOT EXISTS "atendidoPorId" INTEGER,
    ADD COLUMN IF NOT EXISTS "clienteNombre" TEXT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'pedidos_atendidoPorId_fkey'
    ) THEN
        ALTER TABLE "pedidos"
            ADD CONSTRAINT "pedidos_atendidoPorId_fkey"
            FOREIGN KEY ("atendidoPorId") REFERENCES "usuarios"("id")
            ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END $$;

CREATE TABLE "pedido_atenciones" (
    "id" SERIAL NOT NULL,
    "pedidoId" INTEGER NOT NULL,
    "usuarioId" INTEGER,
    "usuarioNombre" TEXT NOT NULL,
    "usuarioRol" "RolUsuario" NOT NULL,
    "accion" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "pedido_atenciones_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "pedido_atenciones_pedidoId_createdAt_idx"
    ON "pedido_atenciones"("pedidoId", "createdAt");

ALTER TABLE "pedido_atenciones"
    ADD CONSTRAINT "pedido_atenciones_pedidoId_fkey"
    FOREIGN KEY ("pedidoId") REFERENCES "pedidos"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "pedido_atenciones"
    ADD CONSTRAINT "pedido_atenciones_usuarioId_fkey"
    FOREIGN KEY ("usuarioId") REFERENCES "usuarios"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;

INSERT INTO "pedido_atenciones" ("pedidoId", "usuarioId", "usuarioNombre", "usuarioRol", "accion", "createdAt")
SELECT p."id", u."id", u."nombre", u."rol", 'REGISTRO', p."createdAt"
FROM "pedidos" p
JOIN "usuarios" u ON u."id" = p."atendidoPorId"
WHERE p."atendidoPorId" IS NOT NULL
  AND u."rol"::TEXT IN ('ADMIN', 'MOZO');

UPDATE "usuarios"
SET "permisos" = array_append("permisos", 'pedidos:ver')
WHERE "rol"::TEXT = 'MOZO'
  AND "permisos" @> ARRAY['pedidos:crear']
  AND NOT ("permisos" @> ARRAY['pedidos:ver']);

UPDATE "usuarios"
SET "permisos" = array_append("permisos", 'pedidos:canal:SALON')
WHERE "rol"::TEXT = 'MOZO'
  AND ("permisos" @> ARRAY['pedidos:ver'] OR "permisos" @> ARRAY['pedidos:crear'])
  AND NOT ("permisos" @> ARRAY['pedidos:canal:SALON']);
