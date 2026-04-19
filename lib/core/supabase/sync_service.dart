import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Capa de acceso genérica a Supabase.
/// Todos los métodos son silenciosos ante errores de red (offline-friendly).
class SyncService {
  static SupabaseClient get _db => Supabase.instance.client;

  // ── Lectura ─────────────────────────────────────────────────────────────────

  /// Descarga todos los registros de una tabla.
  static Future<List<Map<String, dynamic>>> pull(String table) async {
    try {
      final data = await _db
          .from(table)
          .select()
          .timeout(const Duration(seconds: 15));
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      debugPrint('SyncService.pull [$table] error: $e');
      return [];
    }
  }

  // ── Escritura ────────────────────────────────────────────────────────────────

  /// Inserta o actualiza un registro (upsert por id / clave primaria).
  static void upsert(String table, Map<String, dynamic> data) {
    _db.from(table).upsert(data).then((_) {}).catchError((e) {
      debugPrint('SyncService.upsert [$table] error: $e');
    });
  }

  /// Elimina un registro por su clave primaria.
  static void delete(String table, String value, {String key = 'id'}) {
    _db.from(table).delete().eq(key, value).then((_) {}).catchError((_) {});
  }

  /// Sube múltiples registros fila por fila con timeout individual.
  /// Devuelve mensaje de error o null si fue exitoso.
  static Future<String?> pushAll(
      String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return null;
    String? lastError;
    for (final row in rows) {
      try {
        await _db
            .from(table)
            .upsert(row)
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        lastError = e.toString();
        debugPrint('SyncService.pushAll [$table] row error: $e');
      }
    }
    if (lastError == null) {
      debugPrint('SyncService.pushAll [$table] OK (${rows.length} rows)');
    }
    return lastError;
  }

  // ── Singleton (costos) ───────────────────────────────────────────────────────

  /// Descarga el único registro de costos_config.
  static Future<Map<String, dynamic>?> pullSingleton(String table) async {
    try {
      final data = await _db.from(table).select().limit(1);
      final list = List<Map<String, dynamic>>.from(data as List);
      return list.isEmpty ? null : list.first;
    } catch (_) {
      return null;
    }
  }

  /// Upsert del singleton con id fijo.
  static void upsertSingleton(String table, Map<String, dynamic> data) {
    final row = {'id': 'singleton', ...data};
    _db.from(table).upsert(row).then((_) {}).catchError((_) {});
  }

  // ── Real-time ────────────────────────────────────────────────────────────────

  /// Suscripción a cambios en una tabla. Devuelve el channel para cancelarlo
  /// con `Supabase.instance.client.removeChannel(channel)`.
  static RealtimeChannel subscribe(
    String table,
    void Function() onChanged,
  ) {
    final channel = _db.channel('sync_$table');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: (_) => onChanged(),
        )
        .subscribe();
    return channel;
  }
}
