import 'dart:convert';
import 'dart:typed_data';

enum TipoPlato { normal, dieta }

class ComensalModel {
  final String id;
  final String dni;
  final String nombre;
  final TipoPlato tipoPlato;
  final double costoPlato;   // pagado por la empresa
  final bool tieneExtra;
  final double costoExtra;   // adicional (también empresa, tabla aparte)
  final String? firmaBase64; // PNG en base64
  final DateTime fecha;

  const ComensalModel({
    required this.id,
    required this.dni,
    required this.nombre,
    required this.tipoPlato,
    required this.costoPlato,
    this.tieneExtra = false,
    this.costoExtra = 0,
    this.firmaBase64,
    required this.fecha,
  });

  /// Total que carga a la empresa (plato + extra si aplica)
  double get totalEmpresa => costoPlato + (tieneExtra ? costoExtra : 0);

  /// Solo el adicional
  double get totalAdicional => tieneExtra ? costoExtra : 0;

  Uint8List? get firmaBytes =>
      firmaBase64 != null ? base64Decode(firmaBase64!) : null;

  ComensalModel copyWith({
    String? dni,
    String? nombre,
    TipoPlato? tipoPlato,
    double? costoPlato,
    bool? tieneExtra,
    double? costoExtra,
    String? firmaBase64,
    DateTime? fecha,
  }) {
    return ComensalModel(
      id: id,
      dni: dni ?? this.dni,
      nombre: nombre ?? this.nombre,
      tipoPlato: tipoPlato ?? this.tipoPlato,
      costoPlato: costoPlato ?? this.costoPlato,
      tieneExtra: tieneExtra ?? this.tieneExtra,
      costoExtra: costoExtra ?? this.costoExtra,
      firmaBase64: firmaBase64 ?? this.firmaBase64,
      fecha: fecha ?? this.fecha,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'dni': dni,
        'nombre': nombre,
        'tipo_plato': tipoPlato.name,
        'costo_plato': costoPlato,
        'tiene_extra': tieneExtra,
        'costo_extra': costoExtra,
        'firma_base64': firmaBase64,
        'fecha': fecha.toIso8601String(),
      };

  factory ComensalModel.fromMap(Map map) => ComensalModel(
        id: map['id'] as String,
        dni: map['dni'] as String,
        nombre: map['nombre'] as String,
        tipoPlato: TipoPlato.values.firstWhere(
          (t) => t.name == map['tipo_plato'],
          orElse: () => TipoPlato.normal,
        ),
        costoPlato: (map['costo_plato'] as num).toDouble(),
        tieneExtra: map['tiene_extra'] as bool? ?? false,
        costoExtra: (map['costo_extra'] as num? ?? 0).toDouble(),
        firmaBase64: map['firma_base64'] as String?,
        fecha: DateTime.parse(map['fecha'] as String),
      );
}
