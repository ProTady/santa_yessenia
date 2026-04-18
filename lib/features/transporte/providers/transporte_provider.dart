import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../models/transporte_model.dart';

class TransporteNotifier extends Notifier<List<TransporteModel>> {
  Box get _box => Hive.box(AppConstants.transporteBox);

  @override
  List<TransporteModel> build() => _cargar();

  List<TransporteModel> _cargar() {
    return _box.values
        .whereType<Map>()
        .map((m) => TransporteModel.fromMap(m))
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  Future<void> agregar(TransporteModel t) async {
    await _box.put(t.id, t.toMap());
    state = _cargar();
  }

  Future<void> actualizar(TransporteModel t) async {
    await _box.put(t.id, t.toMap());
    state = _cargar();
  }

  Future<void> eliminar(String id) async {
    await _box.delete(id);
    state = _cargar();
  }
}

final transporteProvider =
    NotifierProvider<TransporteNotifier, List<TransporteModel>>(
        TransporteNotifier.new);

final gastoTransporteMesProvider = Provider<double>((ref) {
  final now = DateTime.now();
  final primerDia = DateTime(now.year, now.month, 1);
  return ref.watch(transporteProvider).fold(0.0, (sum, t) {
    if (!t.fecha.isBefore(primerDia)) return sum + t.costo;
    return sum;
  });
});
