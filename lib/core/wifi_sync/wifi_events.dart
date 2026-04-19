import 'dart:async';

/// Canal de eventos para notificar a los providers cuando llegan datos
/// por WiFi. El servidor emite aquí tras cada push exitoso.
class WifiEvents {
  WifiEvents._();

  static final _controller = StreamController<String>.broadcast();

  /// Stream de nombres de tabla que fueron actualizadas por WiFi push.
  static Stream<String> get tableUpdated => _controller.stream;

  /// Llama al recibir datos de una tabla vía WiFi (lo usa el servidor).
  static void notifyTableUpdated(String table) {
    if (!_controller.isClosed) _controller.add(table);
  }
}
