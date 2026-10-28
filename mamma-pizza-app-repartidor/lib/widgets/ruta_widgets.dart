import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/entrega.dart';
import '../providers/entregas_provider.dart';
import '../services/ruta_service.dart';

// ---------------------------------------------------------------------------
// Botón circular flotante sobre el mapa
// ---------------------------------------------------------------------------
class BotonRedondo extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;
  final Color? color;
  const BotonRedondo({super.key, required this.icono, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 46, height: 46, child: Icon(icono, color: color ?? AppColors.dark, size: 22)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Botón compacto (pastilla) que no depende del minimumSize global del tema
// ---------------------------------------------------------------------------
class BotonPildora extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;
  final bool relleno;
  final VoidCallback? onTap;
  const BotonPildora({
    super.key,
    required this.icono,
    required this.texto,
    required this.color,
    this.relleno = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activo = onTap != null;
    final fondo = relleno ? color : color.withValues(alpha: 0.10);
    final frente = relleno ? Colors.white : color;
    return Opacity(
      opacity: activo ? 1 : 0.45,
      child: Material(
        color: fondo,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icono, size: 18, color: frente),
                const SizedBox(width: 6),
                Text(texto, style: TextStyle(color: frente, fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Píldora de estado de la cabecera ("En entrega", "Disponible", "En pausa")
// ---------------------------------------------------------------------------
class PildoraEstado extends StatelessWidget {
  final String texto;
  final Color color;
  const PildoraEstado({super.key, required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 2),
            ),
            child: Center(
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Text(texto, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de ETA sobre el mapa
// ---------------------------------------------------------------------------
class TarjetaEta extends StatelessWidget {
  final RutaInfo? ruta;
  final bool calculando;
  final bool tieneUbicacion;
  final DireccionEntrega destino;
  const TarjetaEta({
    super.key,
    required this.ruta,
    required this.calculando,
    required this.tieneUbicacion,
    required this.destino,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.floating,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.navigation_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: _contenido()),
          const SizedBox(width: 8),
          _MiniBoton(
            texto: "Maps",
            icono: Icons.map_outlined,
            onTap: () => abrirGoogleMaps(destino.lat, destino.lng),
          ),
          const SizedBox(width: 6),
          _MiniBoton(
            texto: "Waze",
            icono: Icons.explore_rounded,
            oscuro: true,
            onTap: () => abrirWaze(destino.lat, destino.lng),
          ),
        ],
      ),
    );
  }

  Widget _contenido() {
    final r = ruta;
    if (r != null) {
      final via = r.via != null ? " por ${r.via}" : "";
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // FittedBox: si no cabe junto a los botones Maps/Waze, el texto se encoge en vez de desbordar
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(r.minutos, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.1)),
                const SizedBox(width: 6),
                Text("(${r.km})", style: const TextStyle(color: AppColors.gray, fontSize: 12.5)),
              ],
            ),
          ),
          Text(
            "${r.trafico}$via",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.gray, fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          calculando ? "Calculando ruta…" : (tieneUbicacion ? "Ruta no disponible" : "Ubicación apagada"),
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
        Text(
          tieneUbicacion ? destino.zona : "Actívala para ver el tiempo de llegada",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.gray, fontSize: 11.5),
        ),
      ],
    );
  }
}

class _MiniBoton extends StatelessWidget {
  final String texto;
  final IconData icono;
  final bool oscuro;
  final VoidCallback onTap;
  const _MiniBoton({required this.texto, required this.icono, required this.onTap, this.oscuro = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: oscuro ? AppColors.primaryDark : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: oscuro ? null : Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 15, color: oscuro ? Colors.white : AppColors.dark),
              const SizedBox(width: 4),
              Text(
                texto,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: oscuro ? Colors.white : AppColors.dark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progreso: Recoger -> En camino -> Entregado
// ---------------------------------------------------------------------------
class ProgresoEntrega extends StatelessWidget {
  final String estado;
  const ProgresoEntrega({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    const pasos = ["Recoger", "En camino", "Entregado"];
    final actual = estado == "EN_CAMINO" ? 1 : (estado == "ENTREGADO" ? 2 : 0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < pasos.length; i++) ...[
          _Paso(texto: pasos[i], hecho: i < actual, actual: i == actual),
          if (i < pasos.length - 1)
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.only(top: 11, left: 4, right: 4),
                decoration: BoxDecoration(
                  color: i < actual ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _Paso extends StatelessWidget {
  final String texto;
  final bool hecho;
  final bool actual;
  const _Paso({required this.texto, required this.hecho, required this.actual});

  @override
  Widget build(BuildContext context) {
    final resaltado = hecho || actual;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: hecho ? AppColors.primary : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: resaltado ? AppColors.primary : AppColors.border, width: 2),
          ),
          child: hecho
              ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
              : actual
                  ? Center(
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      ),
                    )
                  : null,
        ),
        const SizedBox(height: 4),
        Text(
          texto,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: resaltado ? FontWeight.w700 : FontWeight.w500,
            color: resaltado ? AppColors.dark : AppColors.gray,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de cobro: efectivo (con calculadora de vuelto) o pago digital
// ---------------------------------------------------------------------------
class TarjetaCobro extends StatefulWidget {
  final Entrega entrega;
  const TarjetaCobro({super.key, required this.entrega});

  @override
  State<TarjetaCobro> createState() => _TarjetaCobroState();
}

class _TarjetaCobroState extends State<TarjetaCobro> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double? get _paga => double.tryParse(_ctrl.text.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final e = widget.entrega;
    if (!e.esEfectivo) return _pagoDigital(e);

    final paga = _paga;
    final vuelto = paga == null ? null : paga - e.total;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7DE), Color(0xFFFFEDB5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1D074)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: AppColors.warning, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.payments_rounded, color: Colors.white, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFF9A6B00)),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            "ATENCIÓN · PAGO EN DESTINO",
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF9A6B00), letterSpacing: 0.3),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFFFE08A), borderRadius: BorderRadius.circular(8)),
                          child: const Text("EFECTIVO", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF7A5600))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "COBRAR ${soles(e.total)} EN EFECTIVO",
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.dark),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF1D074).withValues(alpha: 0.7)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text("Paga con:", style: TextStyle(fontSize: 12.5, color: AppColors.gray, fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              SizedBox(
                width: 118,
                child: TextField(
                  controller: _ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.spaceMono(fontWeight: FontWeight.w700, fontSize: 13.5),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixText: "S/. ",
                    prefixStyle: GoogleFonts.spaceMono(fontWeight: FontWeight.w700, fontSize: 13.5),
                    hintText: "0.00",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const Spacer(),
              if (vuelto != null) _pildoraVuelto(vuelto),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pildoraVuelto(double vuelto) {
    final falta = vuelto < 0;
    final color = falta ? AppColors.warning : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
      child: Text(
        falta ? "Falta ${soles(-vuelto)}" : "Vuelto: ${soles(vuelto)}",
        style: GoogleFonts.spaceMono(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: falta ? const Color(0xFF7A5600) : AppColors.danger,
        ),
      ),
    );
  }

  Widget _pagoDigital(Entrega e) {
    final pagado = e.pagoEstado == "pagado";
    final color = pagado ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
            child: Icon(pagado ? Icons.verified_rounded : Icons.hourglass_top_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pagado ? "PAGADO · NO COBRES" : "PAGO PENDIENTE",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.3),
                ),
                const SizedBox(height: 2),
                Text("${e.metodoPago} · ${soles(e.total)}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cliente + destino + botón llamar (estilo mockup: fondo lavanda, avatar rosado)
// ---------------------------------------------------------------------------
class TarjetaCliente extends StatelessWidget {
  final Entrega entrega;
  const TarjetaCliente({super.key, required this.entrega});

  String get _subtitulo {
    final dir = entrega.direccion;
    if (dir == null) return "Cliente";
    final corta = dir.zona.split(',').first.trim();
    final ref = dir.referencia?.trim();
    return (ref != null && ref.isNotEmpty) ? "$corta ($ref)" : corta;
  }

  @override
  Widget build(BuildContext context) {
    final e = entrega;
    final telefono = e.clienteTelefono;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE3FA)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(color: Color(0xFFFFDAD4), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              iniciales(e.clienteNombre),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.clienteNombre ?? "Cliente",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 13, color: AppColors.gray),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _subtitulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.gray, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                if (e.direccion != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(Icons.place_rounded, size: 13, color: AppColors.primary),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            e.direccion!.zona,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, color: AppColors.gray),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          BotonPildora(
            icono: Icons.call_rounded,
            texto: "Llamar",
            color: AppColors.success,
            onTap: (telefono == null || telefono.isEmpty) ? null : () => abrirLlamada(telefono),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detalle del pedido
// ---------------------------------------------------------------------------
class ListaPedido extends StatelessWidget {
  final Entrega entrega;
  const ListaPedido({super.key, required this.entrega});

  @override
  Widget build(BuildContext context) {
    final e = entrega;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("PEDIDO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.gray, letterSpacing: 0.6)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  "${e.totalProductos} producto${e.totalProductos == 1 ? '' : 's'}",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in e.items) _fila(item),
          const Divider(height: 18, color: AppColors.border),
          Row(
            children: [
              const Text("Total", style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(soles(e.total), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fila(ItemEntrega item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 30),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
            child: Text("${item.cantidad}x", textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.titulo, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                if (item.agregados.isNotEmpty)
                  Text("+ ${item.agregados.join(', ')}", style: const TextStyle(fontSize: 11.5, color: AppColors.gray)),
                if (item.notas != null && item.notas!.trim().isNotEmpty)
                  Text("“${item.notas}”", style: const TextStyle(fontSize: 11.5, color: AppColors.gray, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(soles(item.subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Switch de disponibilidad (se reutiliza en la pantalla de espera, el perfil y el menú)
// ---------------------------------------------------------------------------
class TarjetaDisponibilidad extends StatelessWidget {
  final EntregasProvider prov;
  final void Function(String mensaje) onError;
  const TarjetaDisponibilidad({super.key, required this.prov, required this.onError});

  @override
  Widget build(BuildContext context) {
    final on = prov.disponible;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: on ? AppColors.success.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: on ? AppColors.success.withValues(alpha: 0.3) : AppColors.border),
      ),
      child: SwitchListTile(
        value: on,
        onChanged: (v) async {
          final error = await prov.cambiarDisponibilidad(v);
          if (error != null) onError(error);
        },
        activeThumbColor: AppColors.success,
        contentPadding: EdgeInsets.zero,
        title: Text(on ? "Disponible" : "En pausa", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
        subtitle: Text(
          on ? "Te pueden asignar pedidos nuevos" : "No recibirás pedidos hasta que vuelvas",
          style: const TextStyle(fontSize: 11.5),
        ),
      ),
    );
  }
}