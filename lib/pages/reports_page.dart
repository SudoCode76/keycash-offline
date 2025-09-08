import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/report_provider.dart';
import '../providers/category_provider.dart';
import '../data/models/category.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportProvider()..init(),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatelessWidget {
  const _ReportsView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cats = context.watch<CategoryProvider>().items;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: const Text('Reportes Mensuales'),
        centerTitle: true,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
          ? _errorState(context, provider.error!, onRetry: provider.load)
          : RefreshIndicator(
        onRefresh: provider.load,
        color: scheme.primary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _monthSelector(
              context,
              year: provider.year,
              month: provider.month,
              onPrev: provider.prevMonth,
              onNext: provider.nextMonth,
            ),
            const SizedBox(height: 12),

            // Totales
            Row(
              children: [
                Expanded(
                  child: _totalCard(
                    context,
                    title: 'Ingresos',
                    value: provider.totalIngresos,
                    color: Colors.green,
                    icon: Icons.arrow_upward_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _totalCard(
                    context,
                    title: 'Gastos',
                    value: provider.totalGastos,
                    color: Colors.red,
                    icon: Icons.arrow_downward_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _totalBalanceCard(context, provider.balance),

            const SizedBox(height: 16),



            const SizedBox(height: 16),

            // Top categorías
            Text(
              'Top categorías',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _categoryBreakdown(
                    context,
                    title: 'Ingresos',
                    totals: provider.ingresosPorCategoria,
                    grandTotal: provider.totalIngresos,
                    cats: cats,
                    positive: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _categoryBreakdown(
                    context,
                    title: 'Gastos',
                    totals: provider.gastosPorCategoria,
                    grandTotal: provider.totalGastos,
                    cats: cats,
                    positive: false,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ---------- Secciones ----------

  Widget _monthSelector(
      BuildContext context, {
        required int year,
        required int month,
        required VoidCallback onPrev,
        required VoidCallback onNext,
      }) {
    final scheme = Theme.of(context).colorScheme;
    final label = _monthNameEs(month) + ' $year';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.05)
            : scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Mes anterior',
          ),
          Expanded(
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Mes siguiente',
          ),
        ],
      ),
    );
  }

  Widget _totalCard(
      BuildContext context, {
        required String title,
        required double value,
        required Color color,
        required IconData icon,
      }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.16) : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? color.withOpacity(0.35) : color.withOpacity(0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bs. ${value.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalBalanceCard(BuildContext context, double balance) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final positive = balance >= 0;

    final List<Color> gradientColors = positive
        ? [
      scheme.primary.withOpacity(isDark ? 0.95 : 1.0),
      scheme.primary.withOpacity(isDark ? 0.65 : 0.75),
    ]
        : [
      Colors.orange.withOpacity(isDark ? 0.9 : 1.0),
      Colors.orange.withOpacity(isDark ? 0.6 : 0.75),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(
            positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Balance del mes',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            'Bs. ${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryBreakdown(
      BuildContext context, {
        required String title,
        required Map<String, double> totals,
        required double grandTotal,
        required List<Category> cats,
        required bool positive,
      }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Ordenar desc y tomar top 5
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                positive ? Icons.north_east_rounded : Icons.south_east_rounded,
                size: 18,
                color: positive ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Sin datos',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          else
            ...top.map((e) {
              final cat = cats.where((c) => c.id == e.key);
              final category = cat.isNotEmpty ? cat.first : null;

              final color = category != null
                  ? _hexToColor(category.color)
                  : (positive ? Colors.green : Colors.red);

              // FIX: clamp devuelve num -> convertir a double
              final double percent = grandTotal > 0
                  ? (e.value / grandTotal).clamp(0.0, 1.0).toDouble()
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: color.withOpacity(0.15),
                      child: Icon(
                        Icons.category,
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category?.nombre ?? 'Categoría',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                            const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 6,
                              value: percent, // double
                              backgroundColor: color.withOpacity(0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Bs. ${e.value.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${(percent * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _errorState(BuildContext context, String message,
      {required Future<void> Function() onRetry}) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: scheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Utils ----------

  String _monthNameEs(int m) {
    const names = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    if (m < 1 || m > 12) return '$m';
    return names[m];
  }

  // FIX: usar 0.0 para que el tipo sea double y no num
  double _maxOfTwo(List<double> a, List<double> b) {
    final double maxA = a.isEmpty ? 0.0 : a.reduce((x, y) => x > y ? x : y);
    final double maxB = b.isEmpty ? 0.0 : b.reduce((x, y) => x > y ? x : y);
    return (maxA > maxB ? maxA : maxB);
  }

  Color _hexToColor(String hex) {
    final v = hex.replaceAll('#', '');
    if (v.length != 6) return Colors.grey;
    return Color(int.parse('FF$v', radix: 16));
  }
}