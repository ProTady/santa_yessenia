import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'wifi_sync_server.dart';

// ── Estado del servidor ────────────────────────────────────────────────────────

class WifiServerState {
  final bool isRunning;
  final String? ip;

  const WifiServerState({this.isRunning = false, this.ip});
}

class WifiServerNotifier extends Notifier<WifiServerState> {
  final _server = WifiSyncServer();

  @override
  WifiServerState build() => const WifiServerState();

  Future<void> toggle() async {
    if (state.isRunning) {
      await _server.stop();
      state = const WifiServerState();
    } else {
      final ip = await _server.start();
      state = WifiServerState(isRunning: ip != null, ip: ip);
    }
  }

  Future<String?> getLocalIp() => WifiSyncServer.localIp();
}

final wifiServerProvider =
    NotifierProvider<WifiServerNotifier, WifiServerState>(
        WifiServerNotifier.new);
