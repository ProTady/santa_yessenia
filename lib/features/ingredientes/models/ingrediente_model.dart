class IngredienteModel {
  final String id;
  final String producto;
  final double cantidad;
  final String unidad;
  final double precioUnitario;
  final String proveedor;
  final DateTime fecha;

  const IngredienteModel({
    required this.id,
    required this.producto,
    required this.cantidad,
    required this.unidad,
    required this.precioUnitario,
    required this.proveedor,
    required this.fecha,
  });

  double get subtotal => cantidad * precioUnitario;

  IngredienteModel copyWith({
    String? producto,
    double? cantidad,
    String? unidad,
    double? precioUnitario,
    String? proveedor,
    DateTime? fecha,
  }) {
    return IngredienteModel(
      id: id,
      producto: producto ?? this.producto,
      cantidad: cantidad ?? this.cantidad,
      unidad: unidad ?? this.unidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      proveedor: proveedor ?? this.proveedor,
      fecha: fecha ?? this.fecha,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'producto': producto,
        'cantidad': cantidad,
        'unidad': unidad,
        'precio_unitario': precioUnitario,
        'proveedor': proveedor,
        'fecha': fecha.toIso8601String(),
      };

  factory IngredienteModel.fromMap(Map map) => IngredienteModel(
        id: map['id'] as String,
        producto: map['producto'] as String,
        cantidad: (map['cantidad'] as num).toDouble(),
        unidad: map['unidad'] as String,
        precioUnitario: (map['precio_unitario'] as num).toDouble(),
        proveedor: map['proveedor'] as String? ?? '',
        fecha: DateTime.parse(map['fecha'] as String),
      );

  static const List<String> unidades = [
    'kg', 'g', 'litros', 'ml', 'unidades', 'cajas', 'bolsas', 'latas', 'docenas',
  ];
}
