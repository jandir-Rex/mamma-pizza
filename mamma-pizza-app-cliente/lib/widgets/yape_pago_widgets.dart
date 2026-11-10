import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';
import '../models/pedido.dart';
import '../services/pedidos_service.dart';

const _borde = Color(0xFFE8E2DA);

BoxDecoration _caja({Color? color, Color? borde}) => BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: borde ?? _borde),
    );

// ---------------------------------------------------------------------------
// Instrucciones de Yape + captura + nombre (checkout y seguimiento)
// ---------------------------------------------------------------------------
class YapeFormulario extends StatefulWidget {
  final double total;
  final XFile? captura;
  final TextEditingController nombreCtrl;
  final ValueChanged<XFile?> onCaptura;
  const YapeFormulario({
    super.key,
    required this.total,
    required this.captura,
    required this.nombreCtrl,
    required this.onCaptura,
  });

  @override
  State<YapeFormulario> createState() => _YapeFormularioState();
}

class _YapeFormularioState extends State<YapeFormulario> {
  ConfigPago? _config;
  bool _cargando = true;
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _cargarConfig();
  }

  @override
  void didUpdateWidget(covariant YapeFormulario old) {
    super.didUpdateWidget(old);
    if (widget.captura == null && _bytes != null) _bytes = null;
  }

  Future<void> _cargarConfig() async {
    try {
      final c = await PedidosService.configPago();
      if (mounted) setState(() => _config = c);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _elegir() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 75);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    if (!mounted) return;
    setState(() => _bytes = bytes);
    widget.onCaptura(f);
  }

  @override
  Widget build(BuildContext context) {
    final numero = _config?.yapeNumero;
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _caja(color: const Color(0xFFF6F0FA), borde: const Color(0xFFD9C7EA)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("1. Yapea S/. ${widget.total.toStringAsFixed(2)} a este número",
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          const SizedBox(height: 8),
          if (_cargando)
            const LinearProgressIndicator(minHeight: 2)
          else if (numero == null || numero.isEmpty)
            const Text("El número de Yape no está disponible. Comunícate con el local.",
                style: TextStyle(color: AppColors.danger, fontSize: 12.5))
          else
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(numero, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                      if ((_config?.yapeTitular ?? "").isNotEmpty)
                        Text(_config!.yapeTitular!, style: const TextStyle(color: AppColors.gray, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: "Copiar número",
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: numero));
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text("Número copiado")));
                  },
                ),
              ],
            ),
          const SizedBox(height: 14),
          const Text("2. Adjunta la captura de tu Yape", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          const SizedBox(height: 8),
          if (_bytes == null)
            OutlinedButton.icon(
              onPressed: _elegir,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text("Adjuntar captura"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          else
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_bytes!, height: 190, width: double.infinity, fit: BoxFit.cover),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: _elegir, child: const Text("Cambiar")),
                    TextButton(
                      onPressed: () {
                        setState(() => _bytes = null);
                        widget.onCaptura(null);
                      },
                      child: const Text("Quitar", style: TextStyle(color: AppColors.danger)),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 12),
          const Text("3. ¿A nombre de quién salió el Yape?", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          const SizedBox(height: 8),
          TextField(
            controller: widget.nombreCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: "Nombre como aparece en la captura",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borde)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Efectivo: ¿con cuánto pagas? (para que el repartidor lleve el vuelto)
// ---------------------------------------------------------------------------
class PagaConSelector extends StatelessWidget {
  final double total;
  final bool exacto;
  final TextEditingController ctrl;
  final ValueChanged<bool> onExacto;
  const PagaConSelector({
    super.key,
    required this.total,
    required this.exacto,
    required this.ctrl,
    required this.onExacto,
  });

  @override
  Widget build(BuildContext context) {
    final sugeridos = [50, 100, 200].where((m) => m >= total).toList();
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _caja(color: const Color(0xFFFFF8E6), borde: const Color(0xFFF2D27A)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("¿Con cuánto pagarás?", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          const Text("Así el repartidor te lleva el vuelto exacto.", style: TextStyle(color: AppColors.gray, fontSize: 12)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text("Monto exacto"),
                selected: exacto,
                onSelected: (_) {
                  ctrl.clear();
                  onExacto(true);
                },
              ),
              for (final m in sugeridos)
                ChoiceChip(
                  label: Text("S/. $m"),
                  selected: !exacto && ctrl.text == "$m",
                  onSelected: (_) {
                    ctrl.text = "$m";
                    onExacto(false);
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onExacto(false),
            decoration: InputDecoration(
              prefixText: "S/. ",
              hintText: "Otro monto",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borde)),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: ctrl,
            builder: (_, v, __) {
              final monto = double.tryParse(v.text.replaceAll(",", "."));
              if (exacto || monto == null) return const SizedBox.shrink();
              if (monto < total) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text("El monto debe ser al menos S/. ${total.toStringAsFixed(2)}",
                      style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text("Vuelto a recibir: S/. ${(monto - total).toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Seguimiento: estado de la revisión del Yape (subir / en revisión / rechazado)
// ---------------------------------------------------------------------------
class ComprobanteYapeCard extends StatefulWidget {
  final Pedido pedido;
  final VoidCallback onEnviado;
  const ComprobanteYapeCard({super.key, required this.pedido, required this.onEnviado});

  @override
  State<ComprobanteYapeCard> createState() => _ComprobanteYapeCardState();
}

class _ComprobanteYapeCardState extends State<ComprobanteYapeCard> {
  XFile? _captura;
  final _nombre = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_captura == null) return setState(() => _error = "Adjunta la captura de tu Yape");
    if (_nombre.text.trim().length < 2) return setState(() => _error = "Indica el nombre de quien yapeó");
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await PedidosService.subirComprobante(widget.pedido.id, imagen: _captura!, yapeNombre: _nombre.text.trim());
      if (!mounted) return;
      setState(() => _captura = null);
      widget.onEnviado();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pedido;

    if (p.comprobanteEstado == "EN_REVISION") {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: _caja(color: const Color(0xFFFFF8E6), borde: const Color(0xFFF2D27A)),
        child: const Row(
          children: [
            Icon(Icons.hourglass_top_rounded, color: Color(0xFFB7791F)),
            SizedBox(width: 12),
            Expanded(
              child: Text("Estamos revisando tu Yape. Te avisaremos apenas lo confirmemos.",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ),
      );
    }

    final rechazado = p.comprobanteEstado == "RECHAZADO";
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: _caja(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rechazado)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: const Color(0xFFFDECEA), borderRadius: BorderRadius.circular(12)),
              child: Text(
                "No pudimos validar tu Yape: ${p.comprobanteMotivo ?? "revisa los datos"}. Sube una nueva captura.",
                style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text("Falta la captura de tu Yape", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          YapeFormulario(
            total: p.total,
            captura: _captura,
            nombreCtrl: _nombre,
            onCaptura: (f) => setState(() => _captura = f),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
            ),
          ElevatedButton(
            onPressed: _enviando ? null : _enviar,
            child: _enviando
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                : const Text("Enviar comprobante"),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Disculpa por demora
// ---------------------------------------------------------------------------
class AvisoDemora extends StatelessWidget {
  final bool enRevision;
  const AvisoDemora({super.key, required this.enRevision});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: _caja(color: const Color(0xFFEEF1FB), borde: const Color(0xFFCBD3F0)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("🙏", style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              enRevision
                  ? "Disculpa la demora. Estamos revisando tu pago y en breve confirmaremos tu pedido."
                  : "Disculpa la demora, estamos con mucha atención en el local. Tu pedido ya está registrado y lo confirmaremos en unos minutos.",
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}