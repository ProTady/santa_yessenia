enum EstadoAsistencia { presente, medioDia, falta, descanso }

extension EstadoExt on EstadoAsistencia {
  String get key => switch (this) {
        EstadoAsistencia.presente  => 'presente',
        EstadoAsistencia.medioDia  => 'medio_dia',
        EstadoAsistencia.falta     => 'falta',
        EstadoAsistencia.descanso  => 'descanso',
      };

  String get label => switch (this) {
        EstadoAsistencia.presente  => 'Presente',
        EstadoAsistencia.medioDia  => 'Medio día',
        EstadoAsistencia.falta     => 'Falta',
        EstadoAsistencia.descanso  => 'Descanso',
      };

  /// Fracción de día que cuenta para el sueldo
  double get fraccion => switch (this) {
        EstadoAsistencia.presente  => 1.0,
        EstadoAsistencia.medioDia  => 0.5,
        EstadoAsistencia.falta     => 0.0,
        EstadoAsistencia.descanso  => 0.0,
      };

  static EstadoAsistencia fromKey(String? k) => switch (k) {
        'presente'  => EstadoAsistencia.presente,
        'medio_dia' => EstadoAsistencia.medioDia,
        'falta'     => EstadoAsistencia.falta,
        'descanso'  => EstadoAsistencia.descanso,
        _           => EstadoAsistencia.presente,
      };
}

class AsistenciaModel {
  /// id compuesto: "${personalId}_${fecha}" — sirve como PK única por trabajador/día
  final String id;
  final String personalId;
  final String fecha; // YYYY-MM-DD
  final EstadoAsistencia estado;
  final String? observacion;

  const AsistenciaModel({
    required this.id,
    required this.personalId,
    required this.fecha,
    required this.estado,
    this.observacion,
  });

  /// Constructor de conveniencia — genera el id automáticamente
  factory AsistenciaModel.crear({
    required String personalId,
    required DateTime fecha,
    required EstadoAsistencia estado,
    String? observacion,
  }) {
    final fechaStr = _fmt(fecha);
    return AsistenciaModel(
      id: '${personalId}_$fechaStr',
      personalId: personalId,
      fecha: fechaStr,
      estado: estado,
      observacion: observacion,
    );
  }

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  DateTime get fechaDate => DateTime.parse(fecha);

  Map<String, dynamic> toMap() => {
        'id': id,
        'personal_id': personalId,
        'fecha': fecha,
        'estado': estado.key,
        'observacion': observacion,
      };

  factory AsistenciaModel.fromMap(Map map) => AsistenciaModel(
        id: map['id'] as String,
        personalId: map['personal_id'] as String,
        fecha: map['fecha'] as String,
        estado: EstadoExt.fromKey(map['estado'] as String?),
        observacion: map['observacion'] as String?,
      );
}
