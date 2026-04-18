import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ingredientes/providers/ingredientes_provider.dart';
import '../../ingresos/providers/ingresos_provider.dart';
import '../../personal/providers/personal_provider.dart';
import '../../suministros/providers/suministros_provider.dart';
import '../../transporte/providers/transporte_provider.dart';
import '../models/dashboard_summary.dart';

final dashboardProvider = Provider<DashboardSummary>((ref) {
  final now = DateTime.now();

  // ── Ingresos del mes ────────────────────────────────────────────────
  final totalIngresos = ref.watch(totalIngresosMesProvider);

  // ── Gastos del mes ──────────────────────────────────────────────────
  final gastoPersonal = ref.watch(gastoPersonalMensualProvider);
  final gastoIngredientes = ref.watch(gastoIngredientesMesProvider);
  final gastoSuministros = ref.watch(gastoSuministrosMesProvider);
  final gastoTransporte = ref.watch(gastoTransporteMesProvider);
  final totalGastos =
      gastoPersonal + gastoIngredientes + gastoSuministros + gastoTransporte;

  // ── Últimos 7 días (ingresos vs gastos por día) ─────────────────────
  final listaIngresos = ref.watch(ingresosProvider);
  final listaIngredientes = ref.watch(ingredientesProvider);
  final listaSuministros = ref.watch(suministrosProvider);
  final listaTransporte = ref.watch(transporteProvider);

  final weeklyData = List.generate(7, (i) {
    final day = now.subtract(Duration(days: 6 - i));
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    bool enDia(DateTime fecha) =>
        !fecha.isBefore(dayStart) && fecha.isBefore(dayEnd);

    final dayIngresos = listaIngresos
        .where((e) => enDia(e.fecha))
        .fold(0.0, (s, e) => s + e.monto);

    final dayGastos = [
      ...listaIngredientes
          .where((e) => enDia(e.fecha))
          .map((e) => e.subtotal),
      ...listaSuministros
          .where((e) => enDia(e.fecha))
          .map((e) => e.costo),
      ...listaTransporte
          .where((e) => enDia(e.fecha))
          .map((e) => e.costo),
    ].fold(0.0, (s, v) => s + v);

    return DailyData(date: dayStart, ingresos: dayIngresos, gastos: dayGastos);
  });

  return DashboardSummary(
    totalIngresos: totalIngresos,
    totalGastos: totalGastos,
    weeklyData: weeklyData,
  );
});

// Desglose de gastos para el dashboard
final desgloseGastosProvider = Provider<Map<String, double>>((ref) {
  return {
    'Personal': ref.watch(gastoPersonalMensualProvider),
    'Ingredientes': ref.watch(gastoIngredientesMesProvider),
    'Suministros': ref.watch(gastoSuministrosMesProvider),
    'Transporte': ref.watch(gastoTransporteMesProvider),
  };
});
