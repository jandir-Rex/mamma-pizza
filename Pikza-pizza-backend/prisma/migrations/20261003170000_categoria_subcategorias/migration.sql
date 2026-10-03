ALTER TABLE "categorias" ADD COLUMN "parentId" INTEGER;

CREATE INDEX "categorias_parentId_idx" ON "categorias"("parentId");

ALTER TABLE "categorias"
ADD CONSTRAINT "categorias_parentId_fkey"
FOREIGN KEY ("parentId") REFERENCES "categorias"("id")
ON DELETE RESTRICT ON UPDATE CASCADE;
