class IngresoModel {
  final String id;
  final String descripcion;
  final double monto;
  final String? numeroBoleta; // referencia de pago
  final DateTime fecha;

  const IngresoModel({
    required this.id,
    required this.descripcion,
    required this.monto,
    this.numeroBoleta,
    required this.fecha,
  });

  IngresoModel copyWith({
    String? descripcion,
    double? monto,
    String? numeroBoleta,
    DateTime? fecha,
  }) {
    return IngresoModel(
      id: id,
      descripcion: descripcion ?? this.descripcion,
      monto: monto ?? this.monto,
      numeroBoleta: numeroBoleta ?? this.numeroBoleta,
      fecha: fecha ?? this.fecha,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'descripcion': descripcion,
        'monto': monto,
        'numero_boleta': numeroBoleta,
        'fecha': fecha.toIso8601String(),
      };

  factory IngresoModel.fromMap(Map map) => IngresoModel(
        id: map['id'] as String,
        descripcion: map['descripcion'] as String,
        monto: (map['monto'] as num).toDouble(),
        numeroBoleta: map['numero_boleta'] as String?,
        fecha: DateTime.parse(map['fecha'] as String),
      );
}
