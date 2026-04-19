import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/sync_service.dart';

// ── Modelo ────────────────────────────────────────────────────────────────────

class BeneficiosConfig {
  /// Gratificación: 2 sueldos/año → 16.67% por defecto
  final double gratificacionPct;
  /// CTS (depósito semestral) → 9.72% por defecto
  final double ctsPct;
  /// Vacaciones: 30 días/año → 8.33% por defecto
  final double vacacionesPct;
  /// EsSalud (aporte empleador) → 9% por defecto
  final double essaludPct;

  const BeneficiosConfig({
    this.gratificacionPct = 16.67,
    this.ctsPct           = 9.72,
    this.vacacionesPct    = 8.33,
    this.essaludPct       = 9.0,
  });

  double get gratificacionFactor => gratificacionPct / 100;
  double get ctsFactor           => ctsPct           / 100;
  double get vacacionesFactor    => vacacionesPct    / 100;
  double get essaludFactor       => essaludPct       / 100;

  double get totalFactor =>
      gratificacionFactor + ctsFactor + vacacionesFactor + essaludFactor;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class BeneficiosNotifier extends Notifier<BeneficiosConfig> {
  static const _keyGrati     = 'beneficio_gratificacion_pct';
  static const _keyCts       = 'beneficio_cts_pct';
  static const _keyVacac     = 'beneficio_vacaciones_pct';
  static const _keyEssalud   = 'beneficio_essalud_pct';
  static const _table        = 'beneficios_config';

  Box get _box => Hive.box(AppConstants.settingsBox);

  @override
  BeneficiosConfig build() {
    _pullFromSupabase();
    return _fromBox();
  }

  BeneficiosConfig _fromBox() => BeneficiosConfig(
        gratificacionPct: (_box.get(_keyGrati,   defaultValue: 16.67) as num).toDouble(),
        ctsPct:           (_box.get(_keyCts,     defaultValue: 9.72)  as num).toDouble(),
        vacacionesPct:    (_box.get(_keyVacac,   defaultValue: 8.33)  as num).toDouble(),
        essaludPct:       (_box.get(_keyEssalud, defaultValue: 9.0)   as num).toDouble(),
      );

  Future<void> _pullFromSupabase() async {
    final row = await SyncService.pullSingleton(_table);
    if (row == null) return;
    await _box.put(_keyGrati,   (row['gratificacion_pct'] as num).toDouble());
    await _box.put(_keyCts,     (row['cts_pct']           as num).toDouble());
    await _box.put(_keyVacac,   (row['vacaciones_pct']    as num).toDouble());
    await _box.put(_keyEssalud, (row['essalud_pct']       as num).toDouble());
    state = _fromBox();
  }

  Future<void> actualizar({
    double? gratificacion,
    double? cts,
    double? vacaciones,
    double? essalud,
  }) async {
    if (gratificacion != null) await _box.put(_keyGrati,   gratificacion);
    if (cts           != null) await _box.put(_keyCts,     cts);
    if (vacaciones    != null) await _box.put(_keyVacac,   vacaciones);
    if (essalud       != null) await _box.put(_keyEssalud, essalud);
    state = _fromBox();
    SyncService.upsertSingleton(_table, {
      'gratificacion_pct': state.gratificacionPct,
      'cts_pct':           state.ctsPct,
      'vacaciones_pct':    state.vacacionesPct,
      'essalud_pct':       state.essaludPct,
    });
  }

  Future<void> restaurarDefectos() async {
    await actualizar(
      gratificacion: 16.67,
      cts:           9.72,
      vacaciones:    8.33,
      essalud:       9.0,
    );
  }
}

final beneficiosProvider =
    NotifierProvider<BeneficiosNotifier, BeneficiosConfig>(
        BeneficiosNotifier.new);
