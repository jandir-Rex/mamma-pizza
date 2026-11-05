// Utilidades de fechas en hora de Lima (UTC-5, sin horario de verano). Todo en formato "YYYY-MM-DD".
const LIMA_OFFSET_MS = 5 * 60 * 60 * 1000;

const aISO = (d) => d.toISOString().slice(0, 10);

function hoyLima(ahora = Date.now()) {
  return aISO(new Date(ahora - LIMA_OFFSET_MS));
}

function sumarDias(iso, n) {
  const d = new Date(`${iso}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + n);
  return aISO(d);
}

// Instante (Date UTC) en que empieza ese dia en Lima: 00:00 Lima = 05:00 UTC
function inicioDiaLima(iso) {
  return new Date(`${iso}T05:00:00Z`);
}

// Dia (en Lima) al que pertenece un instante
function diaLima(fecha) {
  return aISO(new Date(fecha.getTime() - LIMA_OFFSET_MS));
}

// "2026-12" -> { inicio: "2026-12-01", fin: "2026-12-31" }
function periodoDeMes(mes) {
  const [y, m] = mes.split("-").map(Number);
  return {
    inicio: `${y}-${String(m).padStart(2, "0")}-01`,
    fin: aISO(new Date(Date.UTC(y, m, 0))),
  };
}

// Mes siguiente al de la fecha dada ("2026-11-03" -> "2026-12")
function mesSiguiente(iso) {
  const [y, m] = iso.split("-").map(Number);
  const d = new Date(Date.UTC(y, m, 1));
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}`;
}

module.exports = { hoyLima, sumarDias, inicioDiaLima, diaLima, periodoDeMes, mesSiguiente };
