import { useEffect, useEffectEvent, useRef } from "react";
import Datepicker, { type DatepickerLocale } from "flowbite-datepicker/Datepicker";
import { CalenderIcon } from "@/icons";

const localeEspanol: DatepickerLocale = {
  days: ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"],
  daysShort: ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"],
  daysMin: ["Do", "Lu", "Ma", "Mi", "Ju", "Vi", "Sá"],
  months: ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"],
  monthsShort: ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"],
  today: "Hoy",
  monthsTitle: "Meses",
  clear: "Limpiar",
  weekStart: 1,
  format: "dd/mm/yyyy",
};

function fechaComoString(fecha: Date) {
  const anio = fecha.getFullYear();
  const mes = String(fecha.getMonth() + 1).padStart(2, "0");
  const dia = String(fecha.getDate()).padStart(2, "0");
  return `${anio}-${mes}-${dia}`;
}

function fechaComoMostrar(fecha: string) {
  const [anio, mes, dia] = fecha.split("-");
  return `${dia}/${mes}/${anio}`;
}

export default function SelectorFechaPedido({
  id,
  fecha,
  onSeleccionar,
}: {
  id: string;
  fecha: string;
  onSeleccionar: (fecha: string) => void;
}) {
  const inputRef = useRef<HTMLInputElement>(null);
  const notificarSeleccion = useEffectEvent(onSeleccionar);

  useEffect(() => {
    const input = inputRef.current;
    if (!input) return;

    Datepicker.locales.es = localeEspanol;
    const datepicker = new Datepicker(input, {
      autohide: true,
      format: "dd/mm/yyyy",
      language: "es",
      orientation: "bottom left",
      todayBtn: true,
      todayBtnMode: 1,
      todayHighlight: true,
      weekStart: 1,
    });

    const seleccionarFecha = () => {
      const seleccion = datepicker.getDate();
      if (seleccion instanceof Date) {
        notificarSeleccion(fechaComoString(seleccion));
      }
    };
    input.addEventListener("changeDate", seleccionarFecha);

    return () => {
      input.removeEventListener("changeDate", seleccionarFecha);
      datepicker.destroy();
    };
  }, []);

  return (
    <div className="relative w-40">
      <CalenderIcon className="pointer-events-none absolute start-3 top-1/2 size-4 -translate-y-1/2 text-gray-400" />
      <input
        ref={inputRef}
        id={id}
        type="text"
        autoComplete="off"
        aria-label="Seleccionar fecha de pedidos"
        defaultValue={fechaComoMostrar(fecha)}
        placeholder="dd/mm/aaaa"
        className="h-10 w-full rounded-lg border border-gray-300 bg-white py-2 pe-3 ps-9 text-sm text-gray-800 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
      />
    </div>
  );
}
