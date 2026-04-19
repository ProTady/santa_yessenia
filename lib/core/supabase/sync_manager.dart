import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import 'sync_service.dart';

/// Fuerza la subida de TODOS los datos locales (Hive → Supabase).
/// Úsalo cuando los datos no se hayan sincronizado (primer arranque, offline, etc.)
class SyncManager {
  static const _tablas = [
    (box: AppConstants.personalBox,      table: 'personal'),
    (box: AppConstants.ingredientesBox,  table: 'ingredientes'),
    (box: AppConstants.suministrosBox,   table: 'suministros'),
    (box: AppConstants.transporteBox,    table: 'transporte'),
    (box: AppConstants.ingresosBox,      table: 'ingresos'),
    (box: AppConstants.comensalesBox,    table: 'comensales'),
    (box: AppConstants.directorioBox,    table: 'directorio'),
    (box: AppConstants.asistenciasBox,   table: 'asistencias'),
    (box: AppConstants.usuariosBox,      table: 'usuarios'),
    (box: AppConstants.ventasBox,        table: 'ventas'),
  ];

  /// Sube todo y devuelve un mapa tabla → error (null = OK).
  static Future<Map<String, String?>> sincronizarTodo() async {
    final resultados = <String, String?>{};
    for (final entry in _tablas) {
      final box = Hive.box(entry.box);
      final rows = box.values
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
      final error = await SyncService.pushAll(entry.table, rows);
      resultados[entry.table] = error;
    }
    return resultados;
  }
}
