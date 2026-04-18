import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../models/suministro_model.dart';

class SuministrosNotifier extends Notifier<List<SuministroModel>> {
  Box get _box => Hive.box(AppConstants.suministrosBox);

  @override
  List<SuministroModel> build() => _cargar();

  List<SuministroModel> _cargar() {
    return _box.values
        .whereType<Map>()
        .map((m) => SuministroModel.fromMap(m))
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  Future<void> agregar(SuministroModel s) async {
    await _box.put(s.id, s.toMap());
    state = _cargar();
  }

  Future<void> actualizar(SuministroModel s) async {
    await _box.put(s.id, s.toMap());
    state = _cargar();
  }

  Future<void> eliminar(String id) async {
    await _box.delete(id);
    state = _cargar();
  }
}

final suministrosProvider =
    NotifierProvider<SuministrosNotifier, List<SuministroModel>>(
        SuministrosNotifier.new);

// Gasto total del mes actual
final gastoSuministrosMesProvider = Provider<double>((ref) {
  final now = DateTime.now();
  final primerDia = DateTime(now.year, now.month, 1);
  return ref.watch(suministrosProvider).fold(0.0, (sum, s) {
    if (!s.fecha.isBefore(primerDia)) return sum + s.costo;
    return sum;
  });
});

// Separados por tipo para el dashboard
final gastoFijoMesProvider = Provider<double>((ref) {
  final now = DateTime.now();
  final primerDia = DateTime(now.year, now.month, 1);
  return ref.watch(suministrosProvider).fold(0.0, (sum, s) {
    if (!s.fecha.isBefore(primerDia) && s.tipo == TipoSuministro.fijo) {
      return sum + s.costo;
    }
    return sum;
  });
});
