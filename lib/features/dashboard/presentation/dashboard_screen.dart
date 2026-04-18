import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/stat_card.dart';
import '../models/dashboard_summary.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardProvider);
    final desglose = ref.watch(desgloseGastosProvider);
    final now = DateTime.now();
    final monthLabel = DateFormat('MMMM yyyy', 'es').format(now);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(AppConstants.appName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/'),
      body: RefreshIndicator(
        color: AppConstants.primaryGreen,
        onRefresh: () async => ref.invalidate(dashboardProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Green header banner ─────────────────────────────────
              _HeaderBanner(monthLabel: monthLabel, summary: summary),

              const SizedBox(height: 16),

              // ── Stat cards ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Ingresos del Mes',
                        amount: summary.totalIngresos,
                        icon: Icons.trending_up_rounded,
                        color: AppConstants.incomeColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        label: 'Gastos del Mes',
                        amount: summary.totalGastos,
                        icon: Icons.trending_down_rounded,
                        color: AppConstants.expenseColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        label: 'Balance',
                        amount: summary.balance,
                        icon: Icons.account_balance_wallet_rounded,
                        color: AppConstants.incomeColor,
                        isBalance: true,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Desglose de gastos ──────────────────────────────────
              if (summary.totalGastos > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _DesgloseGastos(desglose: desglose),
                ),

              const SizedBox(height: 16),

              // ── Chart ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _WeeklyChart(data: summary.weeklyData),
              ),

              const SizedBox(height: 20),

              // ── Module grid ─────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'MÓDULOS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const _ModuleGrid(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header banner ──────────────────────────────────────────────────────────────

class _HeaderBanner extends StatelessWidget {
  final String monthLabel;
  final DashboardSummary summary;

  const _HeaderBanner({required this.monthLabel, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppConstants.primaryGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de ${_capitalize(monthLabel)}',
            style: const TextStyle(
                color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatCurrency(summary.balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                summary.isPositive ? 'balance positivo' : 'balance negativo',
                style: TextStyle(
                  color: summary.isPositive
                      ? Colors.greenAccent.shade100
                      : Colors.red.shade200,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: AppConstants.localeCode,
      symbol: '${AppConstants.currencySymbol} ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
}

// ── Weekly bar chart ───────────────────────────────────────────────────────────

class _WeeklyChart extends StatelessWidget {
  final List<DailyData> data;

  const _WeeklyChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold<double>(
      100,
      (prev, d) => [prev, d.ingresos, d.gastos].reduce((a, b) => a > b ? a : b),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Últimos 7 días',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const Spacer(),
                _Legend(color: AppConstants.incomeColor, label: 'Ingresos'),
                const SizedBox(width: 12),
                _Legend(color: AppConstants.expenseColor, label: 'Gastos'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal * 1.25,
                  minY: 0,
                  barGroups: data.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.ingresos,
                          color: AppConstants.incomeColor,
                          width: 9,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: e.value.gastos,
                          color: AppConstants.expenseColor,
                          width: 9,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (val, meta) {
                          if (val.toInt() >= data.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('dd/MM').format(data[val.toInt()].date),
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (val, meta) {
                          if (val == 0) return const Text('0', style: TextStyle(fontSize: 9, color: Colors.grey));
                          if (val == meta.max) return const SizedBox();
                          return Text(
                            'S/${val.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 9, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxVal / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppConstants.primaryGreen,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final label = rodIndex == 0 ? 'Ingresos' : 'Gastos';
                        return BarTooltipItem(
                          '$label\nS/ ${rod.toY.toStringAsFixed(2)}',
                          const TextStyle(color: Colors.white, fontSize: 11),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// ── Module navigation grid ─────────────────────────────────────────────────────

class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid();

  static const _modules = [
    _ModuleItem('Personal', Icons.people_rounded, '/personal',
        AppConstants.primaryGreen),
    _ModuleItem('Ingredientes', Icons.kitchen_rounded, '/ingredientes',
        Color(0xFF1565C0)),
    _ModuleItem('Suministros', Icons.propane_tank_rounded, '/suministros',
        Color(0xFF6A1B9A)),
    _ModuleItem('Transporte', Icons.local_shipping_rounded, '/transporte',
        Color(0xFFE65100)),
    _ModuleItem('Ingresos', Icons.payments_rounded, '/ingresos',
        Color(0xFF00695C)),
    _ModuleItem('Reportes', Icons.bar_chart_rounded, '/reportes',
        Color(0xFF37474F)),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
        children: _modules
            .map((m) => _ModuleCard(module: m))
            .toList(),
      ),
    );
  }
}

// ── Desglose de gastos ─────────────────────────────────────────────────────────

class _DesgloseGastos extends StatelessWidget {
  final Map<String, double> desglose;

  const _DesgloseGastos({required this.desglose});

  static const _colores = {
    'Personal': AppConstants.primaryGreen,
    'Ingredientes': Color(0xFF1565C0),
    'Suministros': Color(0xFF6A1B9A),
    'Transporte': Color(0xFFE65100),
  };

  static const _iconos = {
    'Personal': Icons.people_rounded,
    'Ingredientes': Icons.kitchen_rounded,
    'Suministros': Icons.propane_tank_rounded,
    'Transporte': Icons.local_shipping_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
        locale: AppConstants.localeCode,
        symbol: '${AppConstants.currencySymbol} ',
        decimalDigits: 0);
    final total = desglose.values.fold(0.0, (s, v) => s + v);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Desglose de Gastos',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 12),
            ...desglose.entries.map((e) {
              final pct = total > 0 ? e.value / total : 0.0;
              final color = _colores[e.key] ?? Colors.grey;
              final icon = _iconos[e.key] ?? Icons.circle;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: Text(e.key,
                          style: const TextStyle(fontSize: 12)),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade100,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 64,
                      child: Text(fmt.format(e.value),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: color)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ModuleItem {
  final String label;
  final IconData icon;
  final String route;
  final Color color;

  const _ModuleItem(this.label, this.icon, this.route, this.color);
}

class _ModuleCard extends StatelessWidget {
  final _ModuleItem module;

  const _ModuleCard({required this.module});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go(module.route),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: module.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(module.icon, color: module.color, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                module.label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
