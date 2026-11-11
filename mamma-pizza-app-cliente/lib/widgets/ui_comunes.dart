import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'presionable.dart';

/// "hola_mundo" -> "Hola mundo"
String capitalizar(String texto) {
  final limpio = texto.replaceAll("_", " ").trim();
  if (limpio.isEmpty) return limpio;
  return limpio[0].toUpperCase() + limpio.substring(1);
}

// ─────────────────────────────────────────────────────────────
// ENTRADA ESCALONADA (fade + slide). Úsalo con `indice` en listas.
// ─────────────────────────────────────────────────────────────
class Aparecer extends StatelessWidget {
  final Widget child;
  final int indice;
  const Aparecer({super.key, required this.child, this.indice = 0});

  @override
  Widget build(BuildContext context) {
    final i = indice > 8 ? 0 : indice;
    final retraso = AppMotion.stagger.inMilliseconds * i;
    final total = AppMotion.lenta.inMilliseconds + retraso;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(retraso / total, 1, curve: AppMotion.curva),
      builder: (context, v, hijo) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: hijo),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SKELETON (pulso suave, sin paquetes)
// ─────────────────────────────────────────────────────────────
class Esqueleto extends StatefulWidget {
  final double? ancho;
  final double alto;
  final double radio;
  const Esqueleto({super.key, this.ancho, this.alto = 14, this.radio = 8});

  @override
  State<Esqueleto> createState() => _EsqueletoState();
}

class _EsqueletoState extends State<Esqueleto> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: widget.ancho,
        height: widget.alto,
        decoration: BoxDecoration(
          color: Color.lerp(AppColors.border, AppColors.kraftLight, _c.value),
          borderRadius: BorderRadius.circular(widget.radio),
        ),
      ),
    );
  }
}

/// Tarjeta fantasma: imagen + 3 líneas.
class EsqueletoTarjeta extends StatelessWidget {
  final double alto;
  const EsqueletoTarjeta({super.key, this.alto = 96});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: alto,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.bMedio,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Esqueleto(ancho: alto - 24, alto: alto - 24, radio: 16),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Esqueleto(alto: 14),
                SizedBox(height: 8),
                Esqueleto(ancho: 120, alto: 12),
                SizedBox(height: 8),
                Esqueleto(ancho: 60, alto: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ESTADOS: VACÍO y ERROR
// ─────────────────────────────────────────────────────────────
class _EstadoBase extends StatelessWidget {
  final Widget ilustracion;
  final String titulo;
  final String mensaje;
  final String? causa;
  final String? textoAccion;
  final IconData? iconoAccion;
  final VoidCallback? onAccion;

  const _EstadoBase({
    required this.ilustracion,
    required this.titulo,
    required this.mensaje,
    this.causa,
    this.textoAccion,
    this.iconoAccion,
    this.onAccion,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Aparecer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ilustracion,
              const SizedBox(height: 20),
              Text(titulo, textAlign: TextAlign.center, style: AppFonts.titulo(size: 26)),
              const SizedBox(height: 8),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: AppFonts.cuerpo(size: 14, color: AppColors.gray, altura: 1.4),
              ),
              if (causa != null) ...[
                const SizedBox(height: 6),
                Text(
                  causa!,
                  textAlign: TextAlign.center,
                  style: AppFonts.cuerpo(size: 12, color: AppColors.gray),
                ),
              ],
              if (textoAccion != null && onAccion != null) ...[
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: BotonPrincipal(
                    texto: textoAccion!,
                    icono: iconoAccion,
                    onPressed: onAccion,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EstadoVacio extends StatelessWidget {
  final String emoji;
  final String titulo;
  final String mensaje;
  final String? textoAccion;
  final VoidCallback? onAccion;

  const EstadoVacio({
    super.key,
    required this.emoji,
    required this.titulo,
    required this.mensaje,
    this.textoAccion,
    this.onAccion,
  });

  @override
  Widget build(BuildContext context) {
    return _EstadoBase(
      ilustracion: Container(
        width: 104,
        height: 104,
        decoration: const BoxDecoration(color: AppColors.kraftLight, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: ExcludeSemantics(child: Text(emoji, style: const TextStyle(fontSize: 52))),
      ),
      titulo: titulo,
      mensaje: mensaje,
      textoAccion: textoAccion,
      onAccion: onAccion,
    );
  }
}

class EstadoError extends StatelessWidget {
  final String mensaje;
  final String causa;
  final VoidCallback onReintentar;

  const EstadoError({
    super.key,
    this.mensaje = "No pudimos cargar esta información.",
    this.causa = "Suele pasar por una conexión inestable. Revisa tu internet e inténtalo otra vez.",
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return _EstadoBase(
      ilustracion: Container(
        width: 104,
        height: 104,
        decoration: const BoxDecoration(color: AppColors.dangerSoft, shape: BoxShape.circle),
        child: const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.danger),
      ),
      titulo: "Algo salió mal",
      mensaje: mensaje,
      causa: causa,
      textoAccion: "Reintentar",
      iconoAccion: Icons.refresh_rounded,
      onAccion: onReintentar,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MENSAJE DE ERROR EN LÍNEA (aparece/desaparece animado)
// ─────────────────────────────────────────────────────────────
class CajaError extends StatelessWidget {
  final String? mensaje;
  const CajaError({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final m = mensaje;
    return AnimatedSize(
      duration: AppMotion.normal,
      curve: AppMotion.curva,
      alignment: Alignment.topCenter,
      child: m == null
          ? const SizedBox(width: double.infinity)
          : Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(m, style: AppFonts.cuerpo(size: 13, color: AppColors.danger)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PRECIO ANIMADO
// ─────────────────────────────────────────────────────────────
class PrecioAnimado extends StatelessWidget {
  final double valor;
  final TextStyle estilo;
  final String prefijo;
  const PrecioAnimado({
    super.key,
    required this.valor,
    required this.estilo,
    this.prefijo = "S/. ",
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: valor),
      duration: AppMotion.normal,
      curve: AppMotion.curva,
      builder: (context, v, _) => Text("$prefijo${v.toStringAsFixed(2)}", style: estilo),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOTÓN PRINCIPAL (54 px, escala 0.97, háptico, cargando, deshabilitado)
// ─────────────────────────────────────────────────────────────
class BotonPrincipal extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final bool cargando;
  final IconData? icono;
  final bool urgente;

  const BotonPrincipal({
    super.key,
    required this.texto,
    required this.onPressed,
    this.cargando = false,
    this.icono,
    this.urgente = false,
  });

  @override
  Widget build(BuildContext context) {
    final activo = onPressed != null && !cargando;
    final vivo = onPressed != null || cargando;
    final fondo = !vivo ? AppColors.border : (urgente ? AppColors.tomate : AppColors.primary);
    final frente = !vivo ? AppColors.gray : Colors.white;

    return Presionable(
      onTap: activo ? onPressed : null,
      haptico: Haptico.medio,
      etiquetaSemantica: texto,
      child: AnimatedContainer(
        duration: AppMotion.rapida,
        curve: AppMotion.curva,
        height: 54,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(16),
          boxShadow: vivo ? AppShadows.brillo(fondo) : null,
        ),
        child: AnimatedSwitcher(
          duration: AppMotion.rapida,
          child: cargando
              ? const SizedBox(
                  key: ValueKey("cargando"),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                )
              : Row(
                  key: ValueKey(texto),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icono != null) ...[
                      Icon(icono, size: 20, color: frente),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        texto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.cuerpo(size: 15, peso: FontWeight.w600, color: frente),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BARRA INFERIOR (total + CTA)
// ─────────────────────────────────────────────────────────────
class BarraInferior extends StatelessWidget {
  final Widget child;
  const BarraInferior({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: AppShadows.barraInferior,
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SELECTOR DE CANTIDAD (áreas de 48 px)
// ─────────────────────────────────────────────────────────────
class SelectorCantidad extends StatelessWidget {
  final int cantidad;
  final VoidCallback? onMenos;
  final VoidCallback? onMas;
  final bool menosEsEliminar;

  const SelectorCantidad({
    super.key,
    required this.cantidad,
    required this.onMenos,
    required this.onMas,
    this.menosEsEliminar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kraftLight,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BotonCantidad(
            icono: menosEsEliminar ? Icons.delete_outline_rounded : Icons.remove_rounded,
            etiqueta: menosEsEliminar ? "Quitar del pedido" : "Quitar uno",
            color: menosEsEliminar ? AppColors.danger : AppColors.cacao,
            onTap: onMenos,
          ),
          SizedBox(
            width: 28,
            child: AnimatedSwitcher(
              duration: AppMotion.rapida,
              transitionBuilder: (hijo, anim) => ScaleTransition(scale: anim, child: hijo),
              child: Text(
                "$cantidad",
                key: ValueKey(cantidad),
                textAlign: TextAlign.center,
                style: AppFonts.cuerpo(size: 16, peso: FontWeight.w700),
              ),
            ),
          ),
          _BotonCantidad(
            icono: Icons.add_rounded,
            etiqueta: "Agregar uno",
            color: AppColors.primary,
            onTap: onMas,
          ),
        ],
      ),
    );
  }
}

class _BotonCantidad extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final Color color;
  final VoidCallback? onTap;
  const _BotonCantidad({
    required this.icono,
    required this.etiqueta,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activo = onTap != null;
    return Presionable(
      onTap: onTap,
      haptico: Haptico.ligero,
      etiquetaSemantica: etiqueta,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: AnimatedContainer(
            duration: AppMotion.rapida,
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: activo ? Colors.white : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icono,
              size: 18,
              color: activo ? color : AppColors.gray.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TARJETA SELECCIONABLE (dirección, pago, tamaño, agregado)
// ─────────────────────────────────────────────────────────────
class TarjetaSeleccion extends StatelessWidget {
  final bool activo;
  final bool habilitado;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const TarjetaSeleccion({
    super.key,
    required this.activo,
    required this.onTap,
    required this.child,
    this.habilitado = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: habilitado ? 1 : 0.55,
      child: Semantics(
        selected: activo,
        child: Presionable(
          onTap: habilitado ? onTap : null,
          child: AnimatedContainer(
            duration: AppMotion.rapida,
            curve: AppMotion.curva,
            margin: const EdgeInsets.only(bottom: 10),
            padding: padding,
            constraints: const BoxConstraints(minHeight: 56),
            decoration: BoxDecoration(
              color: activo ? AppColors.kraftLight : Colors.white,
              borderRadius: AppRadius.bChico,
              border: Border.all(
                color: activo ? AppColors.primary : AppColors.border,
                width: activo ? 1.6 : 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Radio (círculo) o casilla (cuadrado) animado. Usa check, no solo color.
class IndicadorSeleccion extends StatelessWidget {
  final bool activo;
  final bool cuadrado;
  const IndicadorSeleccion({super.key, required this.activo, this.cuadrado = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.rapida,
      curve: AppMotion.curva,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: activo ? AppColors.primary : Colors.transparent,
        shape: cuadrado ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: cuadrado ? BorderRadius.circular(6) : null,
        border: Border.all(color: activo ? AppColors.primary : AppColors.gray, width: 1.6),
      ),
      child: AnimatedOpacity(
        duration: AppMotion.rapida,
        opacity: activo ? 1 : 0,
        child: const Icon(Icons.check, size: 14, color: Colors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// INSIGNIA DE ESTADO DE PEDIDO (ícono + texto, no solo color)
// ─────────────────────────────────────────────────────────────
class InsigniaEstado extends StatelessWidget {
  final String estado;
  const InsigniaEstado({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final texto = EstadoPedidoUI.colorTexto(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: EstadoPedidoUI.fondo(estado),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(EstadoPedidoUI.icono(estado), size: 14, color: texto),
          const SizedBox(width: 5),
          Text(
            EstadoPedidoUI.etiqueta(estado),
            style: AppFonts.cuerpo(size: 12, peso: FontWeight.w600, color: texto),
          ),
        ],
      ),
    );
  }
}