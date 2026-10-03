// src/pages/Administracion/AnaliticasReportes.tsx
import { useEffect, useState } from "react";
import PanelDetallePedido from "@/components/PanelDetallePedido";
import FilaPedido from "@/components/FilaPedido";
import { Modal } from "@/components/ui/modal";
import {
  leerVariantesCache,
  obtenerVariantesMenu,
} from "@/services/pedidosCache";
import {
  formatoPrecio,
  type Pedido,
  type VarianteInfo,
} from "@/types/pedido";
import { apiRequest } from "@/services/api";
import { useAuth } from "@/context/AuthContext";

type RangoTiempo = "HOY" | "7_DIAS" | "MES";
type AccionRendimiento = "REGISTRO" | "CONTINUACION" | "FINALIZACION";
type PersonaRendimiento = {
  id: number | string;
  nombre: string;
  rol: string;
  registrados: number;
  continuados: number;
  finalizados: number;
};
type Rendimiento = {
  propio: boolean;
  resumen: PersonaRendimiento;
  equipo: PersonaRendimiento[];
  picos: {
    periodo: string;
    actividad: number;
    registrados: number;
    continuados: number;
    finalizados: number;
  }[];
  actividad: {
    id: number;
    pedidoId: number;
    codigo: string;
    accion: AccionRendimiento;
    fecha: string;
    canal: string;
    mesaNumero: number | null;
    total: number;
  }[];
};

type AuditoriaPedidos = {
  pedidos: Pedido[];
  total: number;
  pagina: number;
  limite: number;
  totalPaginas: number;
  iniciadores: { id: number; nombre: string; rol: string }[];
};

type ResumenPedidos = {
  pedidosValidos: number;
  totalFacturado: number;
  ticketPromedio: number;
  canales: { salon: number; paraLlevar: number; delivery: number };
};

function FilaRendimientoStaff({
  staff,
  posicion,
}: {
  staff: PersonaRendimiento;
  posicion: number;
}) {
  return (
    <div className="flex flex-wrap items-center justify-between gap-3 p-4 text-sm">
      <div className="flex items-center gap-3">
        <span className="flex size-7 items-center justify-center rounded-full bg-brand-50 text-xs font-bold text-brand-600 dark:bg-brand-950 dark:text-brand-300">
          #{posicion}
        </span>
        <div>
          <span className="font-bold text-gray-900 dark:text-white">{staff.nombre}</span>
          <span className="ml-2 rounded bg-gray-100 px-2 py-0.5 text-[11px] text-gray-600 dark:bg-gray-800 dark:text-gray-300">{staff.rol}</span>
        </div>
      </div>
      <div className="flex flex-wrap gap-x-5 gap-y-1 text-xs text-gray-500">
        <span>Registró: <strong className="text-gray-800 dark:text-gray-200">{staff.registrados}</strong></span>
        <span>Continuó: <strong className="text-gray-800 dark:text-gray-200">{staff.continuados}</strong></span>
        <span>Finalizó: <strong className="text-gray-800 dark:text-gray-200">{staff.finalizados}</strong></span>
      </div>
    </div>
  );
}

export default function AnaliticasReportes() {
  const { usuario } = useAuth();
  const esAdmin = usuario?.rol === "ADMIN";
  const [rangoTipo, setRangoTipo] = useState<RangoTiempo>("7_DIAS");
  const [resumenPedidos, setResumenPedidos] = useState<ResumenPedidos | null>(null);
  const [rendimiento, setRendimiento] = useState<Rendimiento | null>(null);
  const [equipoExpandido, setEquipoExpandido] = useState(false);
  const [variantesMap, setVariantesMap] = useState<Record<number, VarianteInfo>>(
    () => leerVariantesCache() ?? {}
  );
  const [seleccionado, setSeleccionado] = useState<Pedido | null>(null);
  const [busqueda, setBusqueda] = useState("");
  const [busquedaAplicada, setBusquedaAplicada] = useState("");
  const [estadoAuditoria, setEstadoAuditoria] = useState("TODOS");
  const [canalAuditoria, setCanalAuditoria] = useState("TODOS");
  const [pagoAuditoria, setPagoAuditoria] = useState("TODOS");
  const [iniciadorAuditoria, setIniciadorAuditoria] = useState("TODOS");
  const [paginaAuditoria, setPaginaAuditoria] = useState(1);
  const [limiteAuditoria, setLimiteAuditoria] = useState(10);
  const [auditoria, setAuditoria] = useState<AuditoriaPedidos>({
    pedidos: [],
    total: 0,
    pagina: 1,
    limite: 10,
    totalPaginas: 0,
    iniciadores: [],
  });
  const [cargandoAuditoria, setCargandoAuditoria] = useState(true);
  const [errorAuditoria, setErrorAuditoria] = useState("");
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState("");

  // Al hacer clic en una pestaña se activa la carga sin disparar el linter del efecto
  function cambiarRango(nuevoRango: RangoTiempo) {
    setRangoTipo(nuevoRango);
    setCargando(true);
    setCargandoAuditoria(true);
    setError("");
    setErrorAuditoria("");
    setPaginaAuditoria(1);
    setSeleccionado(null);
  }

  function prepararCambioAuditoria() {
    setCargandoAuditoria(true);
    setErrorAuditoria("");
    setPaginaAuditoria(1);
    setSeleccionado(null);
  }

  useEffect(() => {
    let cancelado = false;

    const ahora = new Date();
    const desde = new Date();

    if (rangoTipo === "HOY") {
      desde.setHours(0, 0, 0, 0);
    } else if (rangoTipo === "7_DIAS") {
      desde.setDate(ahora.getDate() - 7);
      desde.setHours(0, 0, 0, 0);
    } else if (rangoTipo === "MES") {
      desde.setDate(1);
      desde.setHours(0, 0, 0, 0);
    }

    const rango = { desde: desde.toISOString(), hasta: ahora.toISOString() };

    const parametros = new URLSearchParams(rango);
    const solicitudes = [
      apiRequest<Rendimiento>(`/pedidos/rendimiento?${parametros.toString()}`),
      esAdmin
        ? apiRequest<ResumenPedidos>(`/pedidos/resumen?${parametros.toString()}`)
        : Promise.resolve(null),
      esAdmin ? obtenerVariantesMenu() : Promise.resolve({} as Record<number, VarianteInfo>),
    ] as const;

    Promise.all(solicitudes)
      .then(([datosRendimiento, resumen, menu]) => {
        if (cancelado) return;
        setRendimiento(datosRendimiento);
        setResumenPedidos(resumen);
        setVariantesMap(menu);
        setError("");
      })
      .catch((err: unknown) => {
        if (cancelado) return;
        setError(err instanceof Error ? err.message : "Error al cargar reporte");
      })
      .finally(() => {
        if (!cancelado) setCargando(false);
      });

    return () => {
      cancelado = true;
    };
  }, [rangoTipo, esAdmin]);

  useEffect(() => {
    const temporizador = window.setTimeout(() => {
      setBusquedaAplicada(busqueda.trim());
    }, 300);
    return () => window.clearTimeout(temporizador);
  }, [busqueda]);

  useEffect(() => {
    if (!esAdmin) return;

    let cancelado = false;
    const ahora = new Date();
    const desde = new Date();
    if (rangoTipo === "HOY") {
      desde.setHours(0, 0, 0, 0);
    } else if (rangoTipo === "7_DIAS") {
      desde.setDate(ahora.getDate() - 7);
      desde.setHours(0, 0, 0, 0);
    } else {
      desde.setDate(1);
      desde.setHours(0, 0, 0, 0);
    }

    const parametros = new URLSearchParams({
      desde: desde.toISOString(),
      hasta: ahora.toISOString(),
      pagina: String(paginaAuditoria),
      limite: String(limiteAuditoria),
    });
    if (busquedaAplicada) parametros.set("busqueda", busquedaAplicada);
    if (estadoAuditoria !== "TODOS") parametros.set("estado", estadoAuditoria);
    if (canalAuditoria !== "TODOS") parametros.set("canal", canalAuditoria);
    if (pagoAuditoria !== "TODOS") parametros.set("pago", pagoAuditoria);
    if (iniciadorAuditoria !== "TODOS") parametros.set("iniciadoPor", iniciadorAuditoria);

    apiRequest<AuditoriaPedidos>(`/pedidos/auditoria?${parametros.toString()}`)
      .then((resultado) => {
        if (cancelado) return;
        setAuditoria(resultado);
        setSeleccionado((actual) =>
          actual
            ? resultado.pedidos.find((pedido) => pedido.id === actual.id) ?? null
            : null,
        );
        setErrorAuditoria("");
      })
      .catch((err: unknown) => {
        if (cancelado) return;
        setErrorAuditoria(err instanceof Error ? err.message : "No se pudo cargar la auditoría");
      })
      .finally(() => {
        if (!cancelado) setCargandoAuditoria(false);
      });

    return () => {
      cancelado = true;
    };
  }, [
    esAdmin,
    rangoTipo,
    paginaAuditoria,
    limiteAuditoria,
    busquedaAplicada,
    estadoAuditoria,
    canalAuditoria,
    pagoAuditoria,
    iniciadorAuditoria,
  ]);

  // Cálculos de Analíticas
  const pedidosValidos = resumenPedidos?.pedidosValidos ?? 0;
  const totalFacturado = resumenPedidos?.totalFacturado ?? 0;
  const ticketPromedio = resumenPedidos?.ticketPromedio ?? 0;

  const rankingStaff = rendimiento?.equipo ?? [];
  const mejorVendedor = [...rankingStaff].sort(
    (a, b) => b.registrados - a.registrados,
  )[0];

  const picos = rendimiento?.picos ?? [];
  const maxActividad = Math.max(1, ...picos.map((pico) => pico.actividad));
  const resumenPeriodo = esAdmin
    ? rankingStaff.reduce(
        (total, persona) => ({
          registrados: total.registrados + persona.registrados,
          continuados: total.continuados + persona.continuados,
          finalizados: total.finalizados + persona.finalizados,
        }),
        { registrados: 0, continuados: 0, finalizados: 0 },
      )
    : rendimiento?.resumen;

  return (
    <div className="space-y-6">
      {/* Cabecera y Selector de Rango */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            {esAdmin ? "Inteligencia de Negocio" : "Mi desempeño"}
          </p>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            {esAdmin ? "Analíticas & Reportes" : "Mi rendimiento"}
          </h1>
        </div>

        {/* Pestañas de Período */}
        <div className="flex rounded-xl border border-gray-200 bg-white p-1 dark:border-gray-800 dark:bg-gray-800">
          {(["HOY", "7_DIAS", "MES"] as const).map((r) => (
            <button
              key={r}
              type="button"
              onClick={() => cambiarRango(r)}
              className={`rounded-lg px-3.5 py-1.5 text-xs font-bold transition ${
                rangoTipo === r
                  ? "bg-brand-500 text-white shadow-xs"
                  : "text-gray-600 hover:text-gray-900 dark:text-gray-300"
              }`}
            >
              {r === "HOY" ? "Hoy" : r === "7_DIAS" ? "Últimos 7 Días" : "Este Mes"}
            </button>
          ))}
        </div>
      </div>

      {error && <div className="rounded-xl bg-red-50 p-4 text-sm text-red-600">{error}</div>}

      {esAdmin && (
        <section className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-xs dark:border-gray-800 dark:bg-gray-900">
            <p className="text-xs font-bold uppercase tracking-wider text-gray-400">Facturación Total</p>
            <p className="mt-1 text-2xl font-black text-emerald-600 dark:text-emerald-400 tabular-nums">
              {cargando ? "..." : formatoPrecio(totalFacturado)}
            </p>
            <p className="mt-1 text-xs text-gray-500">{pedidosValidos} pedidos no cancelados</p>
          </div>
          <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-xs dark:border-gray-800 dark:bg-gray-900">
            <p className="text-xs font-bold uppercase tracking-wider text-gray-400">Ticket Promedio</p>
            <p className="mt-1 text-2xl font-black text-brand-500 tabular-nums">
              {cargando ? "..." : formatoPrecio(ticketPromedio)}
            </p>
            <p className="mt-1 text-xs text-gray-500">Gasto medio por orden</p>
          </div>
          <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-xs dark:border-gray-800 dark:bg-gray-900">
            <p className="text-xs font-bold uppercase tracking-wider text-gray-400">Canales de Venta</p>
            <div className="mt-2 flex items-center justify-between text-xs font-semibold">
              <span className="text-blue-500">Salón: {resumenPedidos?.canales.salon ?? 0}</span>
              <span className="text-purple-500">Llevar: {resumenPedidos?.canales.paraLlevar ?? 0}</span>
              <span className="text-amber-500">Delivery: {resumenPedidos?.canales.delivery ?? 0}</span>
            </div>
            <p className="mt-1 text-xs text-gray-500">Distribución de volumen</p>
          </div>
          <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-xs dark:border-gray-800 dark:bg-gray-900">
            <p className="text-xs font-bold uppercase tracking-wider text-gray-400">Más comandas registradas</p>
            <p className="mt-1 truncate text-lg font-bold text-gray-900 dark:text-white">
              {cargando ? "..." : mejorVendedor?.nombre ?? "Sin datos"}
            </p>
            <p className="mt-0.5 text-xs font-semibold text-brand-500">
              {mejorVendedor ? `${mejorVendedor.registrados} registros iniciales` : "-"}
            </p>
          </div>
        </section>
      )}

      <div className="grid grid-cols-1 items-start gap-4 xl:grid-cols-2">
      {esAdmin ? (
        <>
          <section className="col-span-1 overflow-hidden rounded-xl border border-gray-200 bg-white shadow-xs dark:border-gray-800 dark:bg-gray-900">
            <div className="border-b border-gray-100 p-5 dark:border-gray-800">
              <h2 className="text-base font-bold text-gray-900 dark:text-white">Rendimiento del equipo</h2>
              <p className="text-xs text-gray-500">Comandas registradas, continuadas y finalizadas por el personal</p>
            </div>
            <div className="divide-y divide-gray-100 dark:divide-gray-800">
              {cargando ? (
                <p className="p-5 text-xs text-gray-400">Calculando rendimiento...</p>
              ) : rankingStaff.length === 0 ? (
                <p className="p-5 text-xs text-gray-400">No hay actividad de personal en este período.</p>
              ) : rankingStaff.slice(0, 4).map((staff, idx) => (
                <FilaRendimientoStaff key={staff.id} staff={staff} posicion={idx + 1} />
              ))}
            </div>
            {!cargando && rankingStaff.length > 4 && (
              <button
                type="button"
                onClick={() => setEquipoExpandido(true)}
                className="w-full border-t border-gray-100 px-5 py-3 text-left text-xs font-semibold text-brand-600 transition-colors hover:bg-gray-50 dark:border-gray-800 dark:text-brand-300 dark:hover:bg-gray-800/50"
              >
                Ver equipo completo ({rankingStaff.length} personas)
              </button>
            )}
          </section>
          <Modal
            isOpen={equipoExpandido}
            onClose={() => setEquipoExpandido(false)}
            className="max-w-2xl"
          >
            <div className="flex h-full min-h-0 flex-col">
              <div className="shrink-0 border-b border-gray-100 px-6 py-5 pr-16 dark:border-gray-800">
                <h2 className="text-base font-bold text-gray-900 dark:text-white">Rendimiento del equipo</h2>
                <p className="text-xs text-gray-500">
                  {rankingStaff.length} personas · Comandas registradas, continuadas y finalizadas
                </p>
              </div>
              <div className="min-h-0 flex-1 divide-y divide-gray-100 overflow-y-auto dark:divide-gray-800">
                {rankingStaff.map((staff, idx) => (
                  <FilaRendimientoStaff key={staff.id} staff={staff} posicion={idx + 1} />
                ))}
              </div>
            </div>
          </Modal>
        </>
      ) : (
        <section className="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-xs dark:border-gray-800 dark:bg-gray-900">
          <div className="border-b border-gray-100 p-5 dark:border-gray-800">
            <h2 className="text-base font-bold text-gray-900 dark:text-white">Mi rendimiento</h2>
            <p className="text-xs text-gray-500">Actividad que realizaste en el período seleccionado</p>
          </div>
          <div className="grid grid-cols-1 divide-y divide-gray-100 sm:grid-cols-3 sm:divide-x sm:divide-y-0 dark:divide-gray-800">
          {[
            { label: "Comandas que registré", value: rendimiento?.resumen.registrados },
            { label: "Comandas que continué", value: rendimiento?.resumen.continuados },
            { label: "Pedidos que finalicé", value: rendimiento?.resumen.finalizados },
          ].map((tarjeta) => (
            <div key={tarjeta.label} className="p-5">
              <p className="text-xs font-bold uppercase tracking-wider text-gray-400">{tarjeta.label}</p>
              <p className="mt-1 text-2xl font-black text-brand-500 tabular-nums">{cargando ? "..." : tarjeta.value ?? 0}</p>
            </div>
          ))}
          </div>
        </section>
      )}

      <section className="min-w-0 rounded-xl border border-gray-200 bg-white p-5 shadow-xs dark:border-gray-800 dark:bg-gray-900">
        <div className="mb-4">
          <h2 className="text-base font-bold text-gray-900 dark:text-white">
            {esAdmin ? "Picos de actividad del equipo" : "Mis picos de actividad"}
          </h2>
          <p className="text-xs text-gray-500">
            {rangoTipo === "HOY" ? "Actividad agrupada por hora" : "Actividad agrupada por día"}
          </p>
        </div>
        {picos.length === 0 ? (
          <p className="py-8 text-center text-xs text-gray-400">
            {cargando ? "Cargando actividad..." : "Aún no hay actividad registrada en este período."}
          </p>
        ) : (
          <div className="flex min-h-40 items-end gap-2 overflow-x-auto border-b border-gray-100 pb-2 dark:border-gray-800">
            {picos.map((pico) => (
              <div key={pico.periodo} className="flex min-w-10 flex-1 flex-col items-center justify-end gap-2">
                <span className="text-[10px] font-semibold text-gray-500">{pico.actividad}</span>
                <div
                  title={`${pico.periodo}: ${pico.registrados} registros, ${pico.continuados} continuaciones, ${pico.finalizados} finalizaciones`}
                  className="w-full max-w-12 rounded-t-md bg-brand-500/80"
                  style={{ height: `${Math.max(5, (pico.actividad / maxActividad) * 112)}px` }}
                />
                <span className="whitespace-nowrap text-[10px] text-gray-500">
                  {rangoTipo === "HOY"
                    ? pico.periodo
                    : new Date(`${pico.periodo}T12:00:00`).toLocaleDateString("es-PE", { day: "2-digit", month: "2-digit" })}
                </span>
              </div>
            ))}
          </div>
        )}
        <div className="mt-3 flex flex-wrap gap-4 text-[11px] text-gray-500">
          <span>Registró: {resumenPeriodo?.registrados ?? 0}</span>
          <span>Continuó: {resumenPeriodo?.continuados ?? 0}</span>
          <span>Finalizó: {resumenPeriodo?.finalizados ?? 0}</span>
          <span className="basis-full text-gray-400">
            El seguimiento de finalizaciones comienza con esta actualización; los pedidos finalizados antes no guardaban quién los cerró.
          </span>
        </div>
      </section>
      </div>

      {!esAdmin && (
        <section className="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-xs dark:border-gray-800 dark:bg-gray-900">
          <div className="border-b border-gray-100 p-5 dark:border-gray-800">
            <h2 className="text-base font-bold text-gray-900 dark:text-white">Mi actividad reciente</h2>
            <p className="text-xs text-gray-500">Solo se muestran tus registros, continuaciones y finalizaciones.</p>
          </div>
          <div className="divide-y divide-gray-100 dark:divide-gray-800">
            {rendimiento?.actividad.length ? rendimiento.actividad.slice(0, 30).map((evento) => (
              <div key={evento.id} className="flex flex-wrap items-center justify-between gap-2 px-5 py-3 text-sm">
                <div>
                  <p className="font-semibold text-gray-900 dark:text-white">{evento.codigo}</p>
                  <p className="text-xs text-gray-500">
                    {evento.accion === "REGISTRO" ? "Registraste la comanda" : evento.accion === "CONTINUACION" ? "Continuaste la comanda" : "Finalizaste el pedido"}
                    {evento.mesaNumero ? ` · Mesa ${evento.mesaNumero}` : ""}
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-xs text-gray-500">{new Date(evento.fecha).toLocaleString("es-PE")}</p>
                  <p className="text-xs font-semibold text-gray-700 dark:text-gray-300">{formatoPrecio(evento.total)}</p>
                </div>
              </div>
            )) : (
              <p className="p-5 text-xs text-gray-400">No tienes actividad registrada en este período.</p>
            )}
          </div>
        </section>
      )}

      {/* La auditoría y sus datos de clientes quedan visibles solo para ADMIN. */}
      {esAdmin && (
      <section className="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-xs dark:border-gray-800 dark:bg-gray-900">
        <div className="space-y-4 border-b border-gray-100 p-5 dark:border-gray-800">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <h2 className="text-base font-bold text-gray-900 dark:text-white">Auditoría Detallada de Órdenes</h2>
              <p className="text-xs text-gray-500">Selecciona cualquier pedido para revisar su ticket</p>
            </div>

            <input
              type="search"
              placeholder="Buscar por código o cliente..."
              value={busqueda}
              onChange={(e) => {
                setBusqueda(e.target.value);
                if (e.target.value.trim() !== busquedaAplicada || paginaAuditoria !== 1) {
                  setCargandoAuditoria(true);
                }
                setPaginaAuditoria(1);
                setSeleccionado(null);
              }}
              className="h-9.5 w-full rounded-lg border border-gray-300 bg-white px-3 text-xs outline-none focus:border-brand-500 sm:w-64 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
            />
          </div>

          <div className="grid grid-cols-1 gap-2 sm:grid-cols-2 xl:grid-cols-4">
            <select
              aria-label="Filtrar por estado"
              value={estadoAuditoria}
              onChange={(e) => {
                prepararCambioAuditoria();
                setEstadoAuditoria(e.target.value);
              }}
              className="h-9.5 rounded-lg border border-gray-300 bg-white px-3 text-xs text-gray-700 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
            >
              <option value="TODOS">Todos los estados</option>
              <option value="PENDIENTE_PAGO">Pendiente de pago</option>
              <option value="CONFIRMADO">Confirmado</option>
              <option value="EN_PREPARACION">En preparación</option>
              <option value="EN_CAMINO">En camino</option>
              <option value="ENTREGADO">Finalizado / entregado</option>
              <option value="CANCELADO">Cancelado</option>
            </select>

            <select
              aria-label="Filtrar por canal"
              value={canalAuditoria}
              onChange={(e) => {
                prepararCambioAuditoria();
                setCanalAuditoria(e.target.value);
              }}
              className="h-9.5 rounded-lg border border-gray-300 bg-white px-3 text-xs text-gray-700 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
            >
              <option value="TODOS">Todos los canales</option>
              <option value="SALON">Salón</option>
              <option value="PARA_LLEVAR">Para llevar</option>
              <option value="DELIVERY">Delivery</option>
            </select>

            <select
              aria-label="Filtrar por pago"
              value={pagoAuditoria}
              onChange={(e) => {
                prepararCambioAuditoria();
                setPagoAuditoria(e.target.value);
              }}
              className="h-9.5 rounded-lg border border-gray-300 bg-white px-3 text-xs text-gray-700 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
            >
              <option value="TODOS">Cualquier estado de pago</option>
              <option value="PAGADO">Pagado</option>
              <option value="PENDIENTE">Pago pendiente</option>
            </select>

            <select
              aria-label="Filtrar por quién inició el pedido"
              value={iniciadorAuditoria}
              onChange={(e) => {
                prepararCambioAuditoria();
                setIniciadorAuditoria(e.target.value);
              }}
              className="h-9.5 rounded-lg border border-gray-300 bg-white px-3 text-xs text-gray-700 outline-none focus:border-brand-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
            >
              <option value="TODOS">Cualquier iniciador</option>
              <option value="CLIENTE">Cliente / sin personal registrado</option>
              {auditoria.iniciadores.map((iniciador) => (
                <option key={iniciador.id} value={iniciador.id}>
                  {iniciador.nombre} · {iniciador.rol === "ADMIN" ? "Mostrador" : iniciador.rol}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="flex min-h-80">
          <div className="flex-1 divide-y divide-gray-100 dark:divide-gray-800">
            {errorAuditoria ? (
              <p role="alert" className="p-5 text-sm text-red-600">{errorAuditoria}</p>
            ) : cargandoAuditoria ? (
              <p className="p-5 text-sm text-gray-500">Cargando pedidos...</p>
            ) : auditoria.pedidos.length === 0 ? (
              <p className="p-5 text-sm text-gray-500">No hay pedidos que coincidan con estos filtros.</p>
            ) : auditoria.pedidos.map((pedido) => (
                <FilaPedido
                  key={pedido.id}
                  pedido={pedido}
                  seleccionado={seleccionado?.id === pedido.id}
                  onClick={() => setSeleccionado(pedido)}
                />
              ))}
          </div>

          {seleccionado && (
            <PanelDetallePedido
              pedido={seleccionado}
              variantesMap={variantesMap}
              onCerrar={() => setSeleccionado(null)}
              onActualizado={() => {}}
              soloLectura
            />
          )}
        </div>

        <div className="flex flex-col gap-3 border-t border-gray-100 px-5 py-3 sm:flex-row sm:items-center sm:justify-between dark:border-gray-800">
          <div className="flex flex-wrap items-center gap-3 text-xs text-gray-500">
            <span>
              {auditoria.total === 0
                ? "0 resultados"
                : `${(paginaAuditoria - 1) * limiteAuditoria + 1}–${Math.min(paginaAuditoria * limiteAuditoria, auditoria.total)} de ${auditoria.total}`}
            </span>
            <label className="flex items-center gap-2">
              Por página
              <select
                aria-label="Cantidad de pedidos por página"
                value={limiteAuditoria}
                onChange={(e) => {
                  setCargandoAuditoria(true);
                  setLimiteAuditoria(Number(e.target.value));
                  setPaginaAuditoria(1);
                  setSeleccionado(null);
                }}
                className="h-8 rounded-md border border-gray-300 bg-white px-2 text-xs text-gray-700 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
              >
                <option value={10}>10</option>
                <option value={20}>20</option>
                <option value={50}>50</option>
              </select>
            </label>
          </div>

          <div className="flex items-center justify-end gap-2">
            <button
              type="button"
              disabled={paginaAuditoria <= 1 || cargandoAuditoria}
              onClick={() => {
                setCargandoAuditoria(true);
                setPaginaAuditoria((pagina) => Math.max(1, pagina - 1));
                setSeleccionado(null);
              }}
              className="h-8 rounded-md border border-gray-300 px-3 text-xs font-semibold text-gray-700 hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-gray-800"
            >
              Anterior
            </button>
            <span className="text-xs text-gray-500">
              Página {paginaAuditoria} de {Math.max(1, auditoria.totalPaginas)}
            </span>
            <button
              type="button"
              disabled={paginaAuditoria >= auditoria.totalPaginas || cargandoAuditoria}
              onClick={() => {
                setCargandoAuditoria(true);
                setPaginaAuditoria((pagina) => pagina + 1);
                setSeleccionado(null);
              }}
              className="h-8 rounded-md border border-gray-300 px-3 text-xs font-semibold text-gray-700 hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-gray-800"
            >
              Siguiente
            </button>
          </div>
        </div>
      </section>
      )}
    </div>
  );
}