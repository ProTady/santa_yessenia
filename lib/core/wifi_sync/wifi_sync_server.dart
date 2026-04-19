import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import 'wifi_events.dart';

/// Servidor HTTP que corre en el dispositivo Admin.
/// Expone los datos de Hive para que los clientes (usuarios) puedan
/// hacer push/pull de sus módulos permitidos.
class WifiSyncServer {
  static const int port = 8765;

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

  HttpServer? _server;
  StreamSubscription<HttpRequest>? _sub;

  bool get isRunning => _server != null;

  // ── Ciclo de vida ──────────────────────────────────────────────────────────

  Future<String?> start() async {
    if (_server != null) return _localIp();
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _sub = _server!.listen(_handle);
      final ip = await _localIp();
      debugPrint('WifiSyncServer started on $ip:$port');
      return ip;
    } catch (e) {
      debugPrint('WifiSyncServer.start error: $e');
      _server = null;
      return null;
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    await _server?.close(force: true);
    _server = null;
    _sub = null;
    debugPrint('WifiSyncServer stopped');
  }

  // ── IP local ───────────────────────────────────────────────────────────────

  static Future<String?> _localIp() async {
    try {
      final ifaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4, includeLinkLocal: false);
      for (final iface in ifaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> localIp() => _localIp();

  // ── Handler de peticiones ──────────────────────────────────────────────────

  Future<void> _handle(HttpRequest req) async {
    req.response.headers
      ..add('Access-Control-Allow-Origin', '*')
      ..contentType = ContentType.json;

    try {
      final segs = req.uri.pathSegments; // e.g. ['pull', 'ventas']
      final method = req.method.toUpperCase();

      if (segs.isEmpty || segs[0] == 'ping') {
        // ── GET /ping ──────────────────────────────────────────────
        _ok(req, {
          'ok': true,
          'name': 'Administrador',
          'tables': _tableBox.keys.toList(),
        });
      } else if (segs[0] == 'pull' && segs.length >= 2 && method == 'GET') {
        // ── GET /pull/{table} ──────────────────────────────────────
        final table = segs[1];
        final boxName = _tableBox[table];
        if (boxName == null) {
          _err(req, 404, 'Unknown table');
          return;
        }
        final box = Hive.box(boxName);
        final rows = box.values
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        req.response.write(jsonEncode(rows));
      } else if (segs[0] == 'push' && segs.length >= 2 && method == 'POST') {
        // ── POST /push/{table} ─────────────────────────────────────
        final table = segs[1];
        final boxName = _tableBox[table];
        if (boxName == null) {
          _err(req, 404, 'Unknown table');
          return;
        }
        final body = await utf8.decoder.bind(req).join();
        final List raw = jsonDecode(body) as List;
        final box = Hive.box(boxName);
        int merged = 0;
        for (final item in raw) {
          final map = Map<String, dynamic>.from(item as Map);
          final id = map['id'] as String?;
          if (id != null) {
            await box.put(id, map);
            merged++;
          }
        }
        // Notificar a los providers que esta tabla cambió
        WifiEvents.notifyTableUpdated(table);
        _ok(req, {'ok': true, 'merged': merged});
      } else {
        _err(req, 404, 'Not found');
      }
    } catch (e) {
      debugPrint('WifiSyncServer handler error: $e');
      _err(req, 500, e.toString());
    } finally {
      await req.response.close();
    }
  }

  void _ok(HttpRequest req, Map<String, dynamic> body) {
    req.response.write(jsonEncode(body));
  }

  void _err(HttpRequest req, int code, String msg) {
    req.response.statusCode = code;
    req.response.write(jsonEncode({'error': msg}));
  }
}
