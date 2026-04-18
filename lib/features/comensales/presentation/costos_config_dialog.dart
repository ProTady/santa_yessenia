import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/costos_provider.dart';

class CostosConfigDialog extends ConsumerStatefulWidget {
  const CostosConfigDialog({super.key});

  @override
  ConsumerState<CostosConfigDialog> createState() => _CostosConfigDialogState();
}

class _CostosConfigDialogState extends ConsumerState<CostosConfigDialog> {
  late final TextEditingController _normalCtrl;
  late final TextEditingController _dietaCtrl;
  late final TextEditingController _extraCtrl;

  @override
  void initState() {
    super.initState();
    final costos = ref.read(costosProvider);
    _normalCtrl = TextEditingController(
        text: costos.costoNormal.toStringAsFixed(2));
    _dietaCtrl =
        TextEditingController(text: costos.costoDieta.toStringAsFixed(2));
    _extraCtrl =
        TextEditingController(text: costos.costoExtra.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _normalCtrl.dispose();
    _dietaCtrl.dispose();
    _extraCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Precios de platos',
          style: TextStyle(
              color: Color(0xFF00838F), fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PriceField(
            ctrl: _normalCtrl,
            label: 'Plato Normal (S/.)',
            icon: Icons.restaurant_rounded,
            color: AppConstants.primaryGreen,
          ),
          const SizedBox(height: 12),
          _PriceField(
            ctrl: _dietaCtrl,
            label: 'Plato Dieta (S/.)',
            icon: Icons.eco_rounded,
            color: Colors.teal,
          ),
          const SizedBox(height: 12),
          _PriceField(
            ctrl: _extraCtrl,
            label: 'Plato Extra / Adicional (S/.)',
            icon: Icons.add_circle_outline_rounded,
            color: Colors.orange,
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00838F)),
          onPressed: () {
            final normal =
                double.tryParse(_normalCtrl.text.replaceAll(',', '.'));
            final dieta =
                double.tryParse(_dietaCtrl.text.replaceAll(',', '.'));
            final extra =
                double.tryParse(_extraCtrl.text.replaceAll(',', '.'));
            if (normal != null && dieta != null && extra != null) {
              ref.read(costosProvider.notifier).actualizar(
                    normal: normal,
                    dieta: dieta,
                    extra: extra,
                  );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Precios actualizados'),
                    backgroundColor: Color(0xFF00838F)),
              );
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _PriceField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final Color color;
  const _PriceField(
      {required this.ctrl,
      required this.label,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d{0,2}'))
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        prefixText: 'S/. ',
      ),
    );
  }
}
