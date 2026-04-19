enum EstadoPago { pagado, fiado }

extension EstadoPagoExt on EstadoPago {
  String get key => this == EstadoPago.pagado ? 'pagado' : 'fiado';
  String get label => this == EstadoPago.pagado ? 'Pagado' : 'Fiado';
  static EstadoPago fromKey(String? k) =>
      k == 'fiado' ? EstadoPago.fiado : EstadoPago.pagado;
}

class VentaModel {
  final String id;
  final DateTime fecha;
  final String descripcion;
  final double cantidad;
  final double valorUnitario;
  final String? comprador;
  final EstadoPago estadoPago;

  const VentaModel({
    required this.id,
    required this.fecha,
    required this.descripcion,
    required this.cantidad,
    required this.valorUnitario,
    this.comprador,
    this.estadoPago = EstadoPago.pagado,
  });

  double get total => cantidad * valorUnitario;

  VentaModel copyWith({
    DateTime? fecha,
    String? descripcion,
    double? cantidad,
    double? valorUnitario,
    String? comprador,
    EstadoPago? estadoPago,
  }) =>
      VentaModel(
        id: id,
        fecha: fecha ?? this.fecha,
        descripcion: descripcion ?? this.descripcion,
        cantidad: cantidad ?? this.cantidad,
        valorUnitario: valorUnitario ?? this.valorUnitario,
        comprador: comprador ?? this.comprador,
        estadoPago: estadoPago ?? this.estadoPago,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'fecha': fecha.toIso8601String(),
        'descripcion': descripcion,
        'cantidad': cantidad,
        'valor_unitario': valorUnitario,
        'comprador': comprador,
        'estado_pago': estadoPago.key,
      };

  factory VentaModel.fromMap(Map map) => VentaModel(
        id: map['id'] as String,
        fecha: DateTime.parse(map['fecha'] as String),
        descripcion: map['descripcion'] as String,
        cantidad: (map['cantidad'] as num).toDouble(),
        valorUnitario: (map['valor_unitario'] as num).toDouble(),
        comprador: map['comprador'] as String?,
        estadoPago: EstadoPagoExt.fromKey(map['estado_pago'] as String?),
      );
}
