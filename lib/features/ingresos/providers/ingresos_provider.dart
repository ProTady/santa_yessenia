import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../models/ingreso_model.dart';

class IngresosNotifier extends Notifier<List<IngresoModel>> {
  Box get _box => Hive.box(AppConstants.ingresosBox);

  @override
  List<IngresoModel> build() => _cargar();

  List<IngresoModel> _cargar() {
    return _box.values
        .whereType<Map>()
        .map((m) => IngresoModel.fromMap(m))
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  Future<void> agregar(IngresoModel i) async {
    await _box.put(i.id, i.toMap());
    state = _cargar();
  }

  Future<void> actualizar(IngresoModel i) async {
    await _box.put(i.id, i.toMap());
    state = _cargar();
  }

  Future<void> eliminar(String id) async {
    await _box.delete(id);
    state = _cargar();
  }
}

final ingresosProvider =
    NotifierProvider<IngresosNotifier, List<IngresoModel>>(
        IngresosNotifier.new);

final totalIngresosMesProvider = Provider<double>((ref) {
  final now = DateTime.now();
  final primerDia = DateTime(now.year, now.month, 1);
  return ref.watch(ingresosProvider).fold(0.0, (sum, i) {
    if (!i.fecha.isBefore(primerDia)) return sum + i.monto;
    return sum;
  });
});
