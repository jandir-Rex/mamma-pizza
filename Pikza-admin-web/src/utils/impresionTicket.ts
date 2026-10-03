import type { Pedido, VarianteInfo } from "@/types/pedido";

function escaparHTML(valor: string) {
  return valor.replace(/[&<>"']/g, (caracter) => {
    const entidades: Record<string, string> = {
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;",
      "'": "&#39;",
    };
    return entidades[caracter];
  });
}

function abrirVentanaImpresion(titulo: string, contenido: string) {
  const ventana = window.open("", "_blank", "width=380,height=600");
  if (!ventana) {
    alert("Por favor habilita las ventanas emergentes en tu navegador");
    return;
  }

  ventana.document.write(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>${escaparHTML(titulo)}</title>
        <style>
          @page { size: 80mm auto; margin: 0; }
          body { font-family: 'Courier New', Courier, monospace; width: 74mm; margin: 0 auto; padding: 10px 5px; color: #000; }
          .center { text-align: center; }
          .line { border-top: 1px dashed #000; margin: 8px 0; }
          .bold { font-weight: bold; }
          .row { display: flex; justify-content: space-between; gap: 8px; font-size: 13px; }
          .item { margin-bottom: 4px; font-size: 13px; overflow-wrap: anywhere; }
          .note { margin: 0 0 5px 10px; font-size: 11px; overflow-wrap: anywhere; }
          .ticket { break-after: page; page-break-after: always; }
          .ticket:last-child { break-after: auto; page-break-after: auto; }
          @media screen { .ticket + .ticket { border-top: 2px dashed #000; margin-top: 16px; padding-top: 16px; } }
        </style>
      </head>
      <body>${contenido}</body>
    </html>
  `);
  ventana.document.close();
  ventana.focus();
  setTimeout(() => {
    ventana.print();
    ventana.close();
  }, 250);
}

function obtenerDatosCabecera(pedido: Pedido) {
  const fechaFormateada = new Date(pedido.createdAt).toLocaleString("es-PE", {
    dateStyle: "short",
    timeStyle: "short",
  });
  const canalTexto = pedido.canal === "DELIVERY"
    ? "DELIVERY"
    : pedido.mesa?.numero
      ? `MESA #${pedido.mesa.numero}`
      : "PARA LLEVAR";
  const responsable = pedido.atendidoPor
    ? `${pedido.atendidoPor.nombre} (${pedido.atendidoPor.rol === "ADMIN" ? "MOSTRADOR" : "MOZO"})`
    : "";

  return { fechaFormateada, canalTexto, responsable };
}

function crearCabeceraTicket(pedido: Pedido, area: "HORNO" | "BARRA", variantesMap: Record<number, VarianteInfo>) {
  const { fechaFormateada, canalTexto, responsable } = obtenerDatosCabecera(pedido);
  const cliente = pedido.clienteNombre || pedido.cliente?.nombre || "CLIENTE EN LOCAL";
  const etiquetaArea = area === "HORNO" ? "HORNO / COCINA" : "BARRA / BEBIDAS";
  const cierre = area === "HORNO" ? "¡PASAR AL HORNO!" : "¡PREPARAR BEBIDAS!";

  const itemsHTML = pedido.items
    .filter((item) => (variantesMap[item.productoVarianteId]?.areaPreparacion ?? "HORNO") === area)
    .map((item) => {
      const variante = variantesMap[item.productoVarianteId];
      const nombre = variante
        ? `${variante.nombre} (${variante.tamano})`
        : `Producto #${item.productoVarianteId}`;
      return `
        <div class="item">${item.cantidad}x ${escaparHTML(nombre)}</div>
        ${item.notas ? `<div class="note">* NOTA: ${escaparHTML(item.notas)}</div>` : ""}
      `;
    })
    .join("");

  return `
    <section class="ticket">
      <div class="center bold" style="font-size: 18px;">MAMMA PIZZA</div>
      <div class="center" style="font-size: 12px;">COMANDA DE ${etiquetaArea}</div>
      <div class="line"></div>
      <div class="row"><span>ORDEN:</span><span class="bold">${escaparHTML(pedido.codigo)}</span></div>
      <div class="row"><span>FECHA:</span><span>${escaparHTML(fechaFormateada)}</span></div>
      <div class="row"><span>ATENCIÓN:</span><span class="bold">${escaparHTML(canalTexto)}</span></div>
      ${responsable ? `<div class="row"><span>RESPONSABLE:</span><span class="bold">${escaparHTML(responsable)}</span></div>` : ""}
      <div class="row"><span>CLIENTE:</span><span>${escaparHTML(cliente)}</span></div>
      <div class="line"></div>
      <div class="row bold"><span>PLATO / ESPECIFICACIÓN</span></div>
      <div class="line"></div>
      ${itemsHTML}
      <div class="line"></div>
      <div class="center bold" style="font-size: 12px; margin-top: 10px;">${cierre}</div>
    </section>
  `;
}

export function imprimirComandasPreparacion(
  pedido: Pedido,
  variantesMap: Record<number, VarianteInfo>,
) {
  const areas: ("HORNO" | "BARRA")[] = ["HORNO", "BARRA"];
  const areasConProductos = areas.filter((area) =>
    pedido.items.some(
      (item) => (variantesMap[item.productoVarianteId]?.areaPreparacion ?? "HORNO") === area,
    ),
  );

  if (areasConProductos.length === 0) {
    alert("El pedido no tiene productos para imprimir.");
    return;
  }

  const tickets = areasConProductos
    .map((area) => crearCabeceraTicket(pedido, area, variantesMap))
    .join("");
  abrirVentanaImpresion(`Comandas de preparación ${pedido.codigo}`, tickets);
}

export function imprimirTicketTermico(
  pedido: Pedido,
  variantesMap: Record<number, VarianteInfo>,
  tipo: "PRECUENTA",
) {
  const { fechaFormateada, canalTexto, responsable } = obtenerDatosCabecera(pedido);
  const cliente = pedido.clienteNombre || pedido.cliente?.nombre || "CLIENTE EN LOCAL";
  const itemsHTML = pedido.items
    .map((item) => {
      const variante = variantesMap[item.productoVarianteId];
      const nombre = variante
        ? `${variante.nombre} (${variante.tamano})`
        : `Producto #${item.productoVarianteId}`;
      const subtotal = (Number(item.precioUnitario) * item.cantidad).toFixed(2);
      return `
        <div class="row" style="margin-bottom: 4px;">
          <span>${item.cantidad}x ${escaparHTML(nombre)}</span>
          <span class="bold">S/ ${subtotal}</span>
        </div>
        ${item.notas ? `<div class="note">* NOTA: ${escaparHTML(item.notas)}</div>` : ""}
      `;
    })
    .join("");

  const contenido = `
    <div class="center bold" style="font-size: 18px;">MAMMA PIZZA</div>
    <div class="center" style="font-size: 12px;">PRE-CUENTA DE SALÓN</div>
    <div class="line"></div>
    <div class="row"><span>ORDEN:</span><span class="bold">${escaparHTML(pedido.codigo)}</span></div>
    <div class="row"><span>FECHA:</span><span>${escaparHTML(fechaFormateada)}</span></div>
    <div class="row"><span>ATENCIÓN:</span><span class="bold">${escaparHTML(canalTexto)}</span></div>
    ${responsable ? `<div class="row"><span>RESPONSABLE:</span><span class="bold">${escaparHTML(responsable)}</span></div>` : ""}
    <div class="row"><span>CLIENTE:</span><span>${escaparHTML(cliente)}</span></div>
    <div class="line"></div>
    <div class="row bold"><span>CANT / DESCRIPCIÓN</span><span>TOTAL</span></div>
    <div class="line"></div>
    ${itemsHTML}
    <div class="line"></div>
    <div class="row bold" style="font-size: 16px; margin: 6px 0;">
      <span>TOTAL A PAGAR:</span>
      <span>S/ ${Number(pedido.total).toFixed(2)}</span>
    </div>
    <div class="center" style="font-size: 11px; margin-top: 10px;">¡Gracias por su visita!</div>
  `;

  abrirVentanaImpresion(`${tipo} ${pedido.codigo}`, contenido);
}
