import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../models/ingrediente_model.dart';

class IngredientesNotifier extends Notifier<List<IngredienteModel>> {
  Box get _box => Hive.box(AppConstants.ingredientesBox);

  @override
  List<IngredienteModel> build() => _cargar();

  List<IngredienteModel> _cargar() {
    return _box.values
        .whereType<Map>()
        .map((m) => IngredienteModel.fromMap(m))
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha)); // más reciente primero
  }

  Future<void> agregar(IngredienteModel ing) async {
    await _box.put(ing.id, ing.toMap());
    state = _cargar();
  }

  Future<void> actualizar(IngredienteModel ing) async {
    await _box.put(ing.id, ing.toMap());
    state = _cargar();
  }

  Future<void> eliminar(String id) async {
    await _box.delete(id);
    state = _cargar();
  }
}

final ingredientesProvider =
    NotifierProvider<IngredientesNotifier, List<IngredienteModel>>(
        IngredientesNotifier.new);

// Gasto total del mes actual
final gastoIngredientesMesProvider = Provider<double>((ref) {
  final now = DateTime.now();
  final primerDiaMes = DateTime(now.year, now.month, 1);
  return ref.watch(ingredientesProvider).fold(0.0, (sum, ing) {
    if (!ing.fecha.isBefore(primerDiaMes)) return sum + ing.subtotal;
    return sum;
  });
});
