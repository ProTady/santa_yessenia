import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../models/directorio_model.dart';

class DirectorioNotifier extends Notifier<List<DirectorioComensal>> {
  Box get _box => Hive.box(AppConstants.directorioBox);

  @override
  List<DirectorioComensal> build() => _cargar();

  List<DirectorioComensal> _cargar() {
    return _box.values
        .whereType<Map>()
        .map((m) => DirectorioComensal.fromMap(m))
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  Future<void> agregar(DirectorioComensal d) async {
    await _box.put(d.dni, d.toMap()); // DNI como clave — evita duplicados
    state = _cargar();
  }

  Future<void> eliminar(String dni) async {
    await _box.delete(dni);
    state = _cargar();
  }

  /// Importa una lista y devuelve cuántos registros se añadieron/actualizaron.
  Future<int> importar(List<DirectorioComensal> lista) async {
    int count = 0;
    for (final d in lista) {
      if (d.dni.length == 8) {
        await _box.put(d.dni, d.toMap());
        count++;
      }
    }
    state = _cargar();
    return count;
  }
}

final directorioProvider =
    NotifierProvider<DirectorioNotifier, List<DirectorioComensal>>(
        DirectorioNotifier.new);

/// Busca un comensal en el directorio por DNI; null si no existe.
final directorioPorDniProvider =
    Provider.family<DirectorioComensal?, String>((ref, dni) {
  final lista = ref.watch(directorioProvider);
  for (final d in lista) {
    if (d.dni == dni) return d;
  }
  return null;
});
