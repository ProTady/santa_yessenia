class DashboardSummary {
  final double totalIngresos;
  final double totalGastos;
  final List<DailyData> weeklyData;

  const DashboardSummary({
    this.totalIngresos = 0,
    this.totalGastos = 0,
    this.weeklyData = const [],
  });

  double get balance => totalIngresos - totalGastos;
  bool get isPositive => balance >= 0;
}

class DailyData {
  final DateTime date;
  final double ingresos;
  final double gastos;

  const DailyData({
    required this.date,
    this.ingresos = 0,
    this.gastos = 0,
  });

  double get balance => ingresos - gastos;
}
