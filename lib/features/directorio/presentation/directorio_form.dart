import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/directorio_model.dart';
import '../providers/directorio_provider.dart';

class DirectorioForm extends ConsumerStatefulWidget {
  final DirectorioComensal? comensal; // null → nuevo
  const DirectorioForm({super.key, this.comensal});

  @override
  ConsumerState<DirectorioForm> createState() => _DirectorioFormState();
}

class _DirectorioFormState extends ConsumerState<DirectorioForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dniCtrl;
  late final TextEditingController _nombreCtrl;
  bool _guardando = false;

  bool get _esEdicion => widget.comensal != null;

  @override
  void initState() {
    super.initState();
    _dniCtrl = TextEditingController(text: widget.comensal?.dni ?? '');
    _nombreCtrl = TextEditingController(text: widget.comensal?.nombre ?? '');
  }

  @override
  void dispose() {
    _dniCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final d = DirectorioComensal(
      dni: _dniCtrl.text.trim(),
      nombre: _nombreCtrl.text.trim(),
    );

    await ref.read(directorioProvider.notifier).agregar(d);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar comensal' : 'Nuevo comensal'),
        backgroundColor: const Color(0xFF00838F),
        actions: [
          TextButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('GUARDAR',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _dniCtrl,
              keyboardType: TextInputType.number,
              maxLength: 8,
              enabled: !_esEdicion, // el DNI es la clave; no se cambia al editar
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'DNI *',
                prefixIcon: Icon(Icons.badge_outlined),
                counterText: '',
                helperText: '8 dígitos',
              ),
              validator: (v) {
                if (v == null || v.trim().length != 8) {
                  return 'El DNI debe tener exactamente 8 dígitos';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre completo *',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00838F),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _guardando ? null : _guardar,
                child: Text(
                  _esEdicion ? 'Guardar cambios' : 'Agregar al directorio',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
