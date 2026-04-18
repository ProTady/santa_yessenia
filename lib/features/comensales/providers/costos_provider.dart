import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';

class CostosConfig {
  final double costoNormal;
  final double costoDieta;
  final double costoExtra;

  const CostosConfig({
    this.costoNormal = 10.0,
    this.costoDieta = 10.0,
    this.costoExtra = 5.0,
  });
}

class CostosNotifier extends Notifier<CostosConfig> {
  static const _keyNormal = 'costo_plato_normal';
  static const _keyDieta  = 'costo_plato_dieta';
  static const _keyExtra  = 'costo_extra';

  @override
  CostosConfig build() {
    final box = Hive.box(AppConstants.settingsBox);
    return CostosConfig(
      costoNormal: (box.get(_keyNormal, defaultValue: 10.0) as num).toDouble(),
      costoDieta:  (box.get(_keyDieta,  defaultValue: 10.0) as num).toDouble(),
      costoExtra:  (box.get(_keyExtra,  defaultValue: 5.0)  as num).toDouble(),
    );
  }

  Future<void> actualizar({double? normal, double? dieta, double? extra}) async {
    final box = Hive.box(AppConstants.settingsBox);
    if (normal != null) await box.put(_keyNormal, normal);
    if (dieta  != null) await box.put(_keyDieta,  dieta);
    if (extra  != null) await box.put(_keyExtra,  extra);
    state = build();
  }
}

final costosProvider =
    NotifierProvider<CostosNotifier, CostosConfig>(CostosNotifier.new);
