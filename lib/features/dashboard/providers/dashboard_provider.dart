import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../models/dashboard_summary.dart';

final dashboardProvider = Provider<DashboardSummary>((ref) {
  final ingresosBox = Hive.box(AppConstants.ingresosBox);
  final ingredientesBox = Hive.box(AppConstants.ingredientesBox);
  final suministrosBox = Hive.box(AppConstants.suministrosBox);
  final transporteBox = Hive.box(AppConstants.transporteBox);

  final now = DateTime.now();
  final firstOfMonth = DateTime(now.year, now.month, 1);

  // ── Ingresos del mes ────────────────────────────────────────────────
  double totalIngresos = 0;
  for (final key in ingresosBox.keys) {
    final item = ingresosBox.get(key);
    if (item is! Map) continue;
    final fecha = _parseDate(item['fecha']);
    if (!fecha.isBefore(firstOfMonth)) {
      totalIngresos += _toDouble(item['monto']);
    }
  }

  // ── Gastos del mes ──────────────────────────────────────────────────
  double gastosIngredientes = 0;
  for (final key in ingredientesBox.keys) {
    final item = ingredientesBox.get(key);
    if (item is! Map) continue;
    final fecha = _parseDate(item['fecha']);
    if (!fecha.isBefore(firstOfMonth)) {
      gastosIngredientes +=
          _toDouble(item['cantidad']) * _toDouble(item['precio_unitario']);
    }
  }

  double gastosSuministros = 0;
  for (final key in suministrosBox.keys) {
    final item = suministrosBox.get(key);
    if (item is! Map) continue;
    final fecha = _parseDate(item['fecha']);
    if (!fecha.isBefore(firstOfMonth)) {
      gastosSuministros += _toDouble(item['costo']);
    }
  }

  double gastosTransporte = 0;
  for (final key in transporteBox.keys) {
    final item = transporteBox.get(key);
    if (item is! Map) continue;
    final fecha = _parseDate(item['fecha']);
    if (!fecha.isBefore(firstOfMonth)) {
      gastosTransporte += _toDouble(item['costo']);
    }
  }

  final totalGastos = gastosIngredientes + gastosSuministros + gastosTransporte;

  // ── Últimos 7 días ──────────────────────────────────────────────────
  final weeklyData = List.generate(7, (i) {
    final day = now.subtract(Duration(days: 6 - i));
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    double dayIngresos = 0;
    for (final key in ingresosBox.keys) {
      final item = ingresosBox.get(key);
      if (item is! Map) continue;
      final fecha = _parseDate(item['fecha']);
      if (!fecha.isBefore(dayStart) && fecha.isBefore(dayEnd)) {
        dayIngresos += _toDouble(item['monto']);
      }
    }

    double dayGastos = 0;
    for (final key in ingredientesBox.keys) {
      final item = ingredientesBox.get(key);
      if (item is! Map) continue;
      final fecha = _parseDate(item['fecha']);
      if (!fecha.isBefore(dayStart) && fecha.isBefore(dayEnd)) {
        dayGastos += _toDouble(item['cantidad']) * _toDouble(item['precio_unitario']);
      }
    }
    for (final box in [suministrosBox, transporteBox]) {
      for (final key in box.keys) {
        final item = box.get(key);
        if (item is! Map) continue;
        final fecha = _parseDate(item['fecha']);
        if (!fecha.isBefore(dayStart) && fecha.isBefore(dayEnd)) {
          dayGastos += _toDouble(item['costo']);
        }
      }
    }

    return DailyData(date: dayStart, ingresos: dayIngresos, gastos: dayGastos);
  });

  return DashboardSummary(
    totalIngresos: totalIngresos,
    totalGastos: totalGastos,
    weeklyData: weeklyData,
  );
});

DateTime _parseDate(dynamic value) {
  if (value is String) return DateTime.tryParse(value) ?? DateTime(2000);
  return DateTime(2000);
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return 0;
}
