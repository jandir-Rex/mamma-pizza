CREATE TABLE "forecast_runs" (
    "id" SERIAL NOT NULL,
    "periodoInicio" DATE NOT NULL,
    "periodoFin" DATE NOT NULL,
    "fechaCorte" DATE NOT NULL,
    "estado" TEXT NOT NULL,
    "solicitadoPorId" INTEGER,
    "resultado" JSONB,
    "error" TEXT,
    "duracionMs" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "forecast_runs_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "forecast_runs_createdAt_idx" ON "forecast_runs"("createdAt");
