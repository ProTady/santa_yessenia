class TransporteModel {
  final String id;
  final String origen;
  final String destino;
  final String motivo; // Compras, Personal, Suministros, Otros
  final double costo;
  final String? descripcion;
  final DateTime fecha;

  const TransporteModel({
    required this.id,
    required this.origen,
    required this.destino,
    required this.motivo,
    required this.costo,
    this.descripcion,
    required this.fecha,
  });

  TransporteModel copyWith({
    String? origen,
    String? destino,
    String? motivo,
    double? costo,
    String? descripcion,
    DateTime? fecha,
  }) {
    return TransporteModel(
      id: id,
      origen: origen ?? this.origen,
      destino: destino ?? this.destino,
      motivo: motivo ?? this.motivo,
      costo: costo ?? this.costo,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'origen': origen,
        'destino': destino,
        'motivo': motivo,
        'costo': costo,
        'descripcion': descripcion,
        'fecha': fecha.toIso8601String(),
      };

  factory TransporteModel.fromMap(Map map) => TransporteModel(
        id: map['id'] as String,
        origen: map['origen'] as String,
        destino: map['destino'] as String,
        motivo: map['motivo'] as String? ?? 'Otros',
        costo: (map['costo'] as num).toDouble(),
        descripcion: map['descripcion'] as String?,
        fecha: DateTime.parse(map['fecha'] as String),
      );

  static const List<String> motivos = [
    'Compras',
    'Personal',
    'Suministros',
    'Entrega',
    'Otros',
  ];

  String get rutaCompleta => '$origen → $destino';
}
