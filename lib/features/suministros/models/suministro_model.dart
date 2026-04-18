enum TipoSuministro { fijo, variable }

class SuministroModel {
  final String id;
  final String nombre;
  final String categoria; // Gas, Utensilios, Limpieza, Otros
  final TipoSuministro tipo;
  final double costo;
  final String? descripcion;
  final DateTime fecha;

  const SuministroModel({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.tipo,
    required this.costo,
    this.descripcion,
    required this.fecha,
  });

  SuministroModel copyWith({
    String? nombre,
    String? categoria,
    TipoSuministro? tipo,
    double? costo,
    String? descripcion,
    DateTime? fecha,
  }) {
    return SuministroModel(
      id: id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      tipo: tipo ?? this.tipo,
      costo: costo ?? this.costo,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'categoria': categoria,
        'tipo': tipo.name,
        'costo': costo,
        'descripcion': descripcion,
        'fecha': fecha.toIso8601String(),
      };

  factory SuministroModel.fromMap(Map map) => SuministroModel(
        id: map['id'] as String,
        nombre: map['nombre'] as String,
        categoria: map['categoria'] as String? ?? 'Otros',
        tipo: TipoSuministro.values.firstWhere(
          (t) => t.name == map['tipo'],
          orElse: () => TipoSuministro.variable,
        ),
        costo: (map['costo'] as num).toDouble(),
        descripcion: map['descripcion'] as String?,
        fecha: DateTime.parse(map['fecha'] as String),
      );

  static const List<String> categorias = [
    'Gas',
    'Utensilios',
    'Limpieza',
    'Menaje',
    'Electricidad',
    'Agua',
    'Otros',
  ];
}
