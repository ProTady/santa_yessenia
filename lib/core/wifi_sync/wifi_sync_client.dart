import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

/// Cliente WiFi para dispositivos de usuario.
/// Se conecta al servidor del Admin en la misma red local.
class WifiSyncClient {
  static const int port = 8765;
  static const Duration _timeout = Duration(seconds: 12);

  static const _tableBox = {
    'personal':     AppConstants.personalBox,
    'ingredientes': AppConstants.ingredientesBox,
    'suministros':  AppConstants.suministrosBox,
    'transporte':   AppConstants.transporteBox,
    'ingresos':     AppConstants.ingresosBox,
    'comensales':   AppConstants.comensalesBox,
    'directorio':   AppConstants.directorioBox,
    'asistencias':  AppConstants.asistenciasBox,
    'ventas':       AppConstants.ventasBox,
    'usuarios':     AppConstants.usuariosBox,
  };

  final String adminIp;
  WifiSyncClient(this.adminIp);

  String get _base => 'http://$adminIp:$port';

  // ── Ping ───────────────────────────────────────────────────────────────────

  Future<bool> ping() async {
    try {
      final resp = await _get('/ping');
      final json = jsonDecode(resp) as Map;
      return json['ok'] == true;
    } catch (e) {
      debugPrint('WifiSyncClient.ping error: $e');
      return false;
    }
  }

  // ── Push: sube datos locales al Admin ─────────────────────────────────────

  /// Sube los datos locales de [tables] al servidor Admin.
  /// Retorna mapa tabla → error (null = OK).
  Future<Map<String, String?>> push(List<String> tables) async {
    final results = <String, String?>{};
    for (final table in tables) {
      final boxName = _tableBox[table];
      if (boxName == null) continue;
      try {
        final box = Hive.box(boxName);
        final rows = box.values
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        if (rows.isEmpty) {
          results[table] = null;
          continue;
        }
        final resp = await _post('/push/$table', jsonEncode(rows));
        final json = jsonDecode(resp) as Map;
        results[table] = json['ok'] == true ? null : json['error']?.toString();
      } catch (e) {
        results[table] = e.toString();
        debugPrint('WifiSyncClient.push [$table] error: $e');
      }
    }
    return results;
  }

  // ── Pull: descarga datos del Admin ─────────────────────────────────────────

  /// Descarga los datos de [tables] desde el Admin y los guarda en Hive.
  /// Retorna mapa tabla → error (null = OK).
  Future<Map<String, String?>> pull(List<String> tables) async {
    final results = <String, String?>{};
    for (final table in tables) {
      final boxName = _tableBox[table];
      if (boxName == null) continue;
      try {
        final body = await _get('/pull/$table');
        final List rows = jsonDecode(body) as List;
        final box = Hive.box(boxName);
        for (final row in rows) {
          final map = Map<String, dynamic>.from(row as Map);
          final id = map['id'] as String?;
          if (id != null) await box.put(id, map);
        }
        results[table] = null;
      } catch (e) {
        results[table] = e.toString();
        debugPrint('WifiSyncClient.pull [$table] error: $e');
      }
    }
    return results;
  }

  // ── HTTP helpers ───────────────────────────────────────────────────────────

  Future<String> _get(String path) async {
    final client = HttpClient()..connectionTimeout = _timeout;
    final req = await client.getUrl(Uri.parse('$_base$path'));
    final resp = await req.close().timeout(_timeout);
    return utf8.decoder.bind(resp).join();
  }

  Future<String> _post(String path, String body) async {
    final client = HttpClient()..connectionTimeout = _timeout;
    final req = await client.postUrl(Uri.parse('$_base$path'));
    req.headers.contentType = ContentType.json;
    req.write(body);
    final resp = await req.close().timeout(_timeout);
    return utf8.decoder.bind(resp).join();
  }
}
