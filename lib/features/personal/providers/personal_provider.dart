import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../models/personal_model.dart';

class PersonalNotifier extends Notifier<List<PersonalModel>> {
  Box get _box => Hive.box(AppConstants.personalBox);

  @override
  List<PersonalModel> build() => _cargar();

  List<PersonalModel> _cargar() {
    return _box.values
        .whereType<Map>()
        .map((m) => PersonalModel.fromMap(m))
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  Future<void> agregar(PersonalModel p) async {
    await _box.put(p.id, p.toMap());
    state = _cargar();
  }

  Future<void> actualizar(PersonalModel p) async {
    await _box.put(p.id, p.toMap());
    state = _cargar();
  }

  Future<void> eliminar(String id) async {
    await _box.delete(id);
    state = _cargar();
  }

  Future<void> toggleActivo(PersonalModel p) async {
    await actualizar(p.copyWith(activo: !p.activo));
  }
}

final personalProvider =
    NotifierProvider<PersonalNotifier, List<PersonalModel>>(PersonalNotifier.new);

// Solo activos — para usarlo en el dashboard y costos
final personalActivoProvider = Provider<List<PersonalModel>>((ref) {
  return ref.watch(personalProvider).where((p) => p.activo).toList();
});

// Gasto mensual total en personal (activos)
final gastoPersonalMensualProvider = Provider<double>((ref) {
  return ref
      .watch(personalActivoProvider)
      .fold(0.0, (sum, p) => sum + p.sueldoMensual);
});
