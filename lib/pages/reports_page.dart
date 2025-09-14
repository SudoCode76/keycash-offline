import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/report_provider.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';

import '../data/models/category.dart';
import '../data/models/transaction.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ReportsView();
  }
}

class _ReportsView extends StatelessWidget {
  const _ReportsView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final cats = context.watch<CategoryProvider>().items;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: const Text('Reportes Mensuales'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: provider.load,
          ),
        ],
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

            // Top categorías en columna: Gastos debajo de Ingresos
            _topCategoriesColumn(context, provider, cats),
            const SizedBox(height: 16),

            // Transacciones por día (contraídas por defecto + edición + totales al expandir)
            _transactionsByDay(context, provider, cats),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ---------- Top categorías (vertical: Ingresos y debajo Gastos) ----------
  Widget _topCategoriesColumn(
      BuildContext context, ReportProvider provider, List<Category> cats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top categorías',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        _categoryCard(
          context,
          title: 'Ingresos',
          positive: true,
          totals: provider.ingresosPorCategoria,
          grandTotal: provider.totalIngresos,
          cats: cats,
        ),
        const SizedBox(height: 12),
        _categoryCard(
          context,
          title: 'Gastos',
          positive: false,
          totals: provider.gastosPorCategoria,
          grandTotal: provider.totalGastos,
          cats: cats,
        ),
      ],
    );
  }

  Widget _categoryCard(
      BuildContext context, {
        required String title,
        required bool positive,
        required Map<String, double> totals,
        required double grandTotal,
        required List<Category> cats,
      }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();

    final headerColor = positive ? Colors.green : Colors.red;
    final bg = isDark ? scheme.surfaceVariant.withOpacity(0.15) : scheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
          isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: headerColor.withOpacity(isDark ? 0.18 : 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  positive ? Icons.north_east_rounded : Icons.south_east_rounded,
                  color: headerColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
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
            ...top.asMap().entries.map((e) {
              final catId = e.value.key;
              final value = e.value.value;
              final idx = e.key + 1;
              final category = cats.firstWhere(
                    (c) => c.id == catId,
                orElse: () => Category(
                  id: catId,
                  nombre: 'Categoría',
                  tipo: positive ? 'ingreso' : 'gasto',
                  color: positive ? '#4CAF50' : '#F44336',
                  icono: 'mi:category',
                  activo: true,
                  created: '',
                  orden: 0,
                ),
              );
              final color = _hexToColor(category.color);
              final percent =
              grandTotal > 0 ? (value / grandTotal).clamp(0.0, 1.0) : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        '$idx.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 6,
                              value: percent,
                              backgroundColor: color.withOpacity(0.15),
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
                          'Bs. ${value.toStringAsFixed(0)}',
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

  // ---------- Transacciones por día (contraídas por defecto + edición + totales al expandir) ----------
  Widget _transactionsByDay(
      BuildContext context, ReportProvider provider, List<Category> cats) {
    final scheme = Theme.of(context).colorScheme;
    final txs = provider.txs;

    if (txs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'No hay transacciones este mes.',
          style: TextStyle(color: scheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      );
    }

    final Map<String, List<TransactionModel>> grouped = {};
    for (final t in txs) {
      grouped.putIfAbsent(t.fecha, () => []).add(t);
    }
    final dates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transacciones por día',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...dates.map((fecha) {
          final list = grouped[fecha]!..sort((a, b) => b.created.compareTo(a.created));

          double ingresos = 0, gastos = 0;
          for (final t in list) {
            if (t.tipo == 'ingreso') ingresos += t.monto;
            if (t.tipo == 'gasto') gastos += t.monto;
          }
          final balanceDia = ingresos - gastos;
          final pos = balanceDia >= 0;
          final chipColor = pos ? Colors.green : Colors.red;

          const initiallyExpanded = false;

          return Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              color: scheme.surfaceVariant.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.13 : 0.94,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.06),
                ),
              ),
              child: ExpansionTile(
                initiallyExpanded: initiallyExpanded,
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        fecha,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        'Bs. ${balanceDia.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      backgroundColor: chipColor.withOpacity(0.15),
                      labelStyle: TextStyle(color: chipColor),
                      side: BorderSide(color: chipColor.withOpacity(0.45)),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                      child: Text(
                        '${list.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 2, 6, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _dayTotalChip(
                            context,
                            label: 'Ingresos',
                            value: ingresos,
                            color: Colors.green,
                            icon: Icons.arrow_upward_rounded,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dayTotalChip(
                            context,
                            label: 'Gastos',
                            value: gastos,
                            color: Colors.red,
                            icon: Icons.arrow_downward_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...list.map((t) {
                    final isIngreso = t.tipo == 'ingreso';
                    final color = isIngreso ? Colors.green : Colors.red;
                    final category = cats.firstWhere(
                          (c) => c.id == t.categoriaId,
                      orElse: () => Category(
                        id: t.categoriaId,
                        nombre: isIngreso ? 'Ingreso' : 'Gasto',
                        tipo: t.tipo,
                        color: isIngreso ? '#4CAF50' : '#F44336',
                        icono: 'mi:category',
                        activo: true,
                        created: '',
                        orden: 0,
                      ),
                    );
                    final catColor = _hexToColor(category.color);

                    return ListTile(
                      dense: true,
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: catColor.withOpacity(0.15),
                        child: Icon(
                          isIngreso ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          color: catColor,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        category.nombre,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: t.descripcion.isNotEmpty
                          ? Text(
                        t.descripcion,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      )
                          : null,
                      trailing: Text(
                        '${isIngreso ? '+' : '-'}Bs. ${t.monto.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => _openEditTransactionSheet(context, t),
                    );
                  }),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _dayTotalChip(
      BuildContext context, {
        required String label,
        required double value,
        required Color color,
        required IconData icon,
      }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.16) : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? color.withOpacity(0.35) : color.withOpacity(0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            'Bs. ${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  void _openEditTransactionSheet(BuildContext context, TransactionModel t) {
    final txProv = context.read<TransactionProvider>();
    final catProv = context.read<CategoryProvider>();
    final reportProv = context.read<ReportProvider>();

    final montoCtrl = TextEditingController(text: t.monto.toStringAsFixed(2));
    final descCtrl = TextEditingController(text: t.descripcion);
    String tipo = t.tipo;
    String? categoriaId = t.categoriaId;
    DateTime fecha = DateTime.parse('${t.fecha}T00:00:00');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final insets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: insets.bottom),
          child: StatefulBuilder(
            builder: (context, setSt) {
              final cats =
              catProv.items.where((c) => c.activo && c.tipo == tipo).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Editar transacción',
                        style: Theme.of(ctx)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                            value: 'gasto',
                            label: Text('Gasto'),
                            icon: Icon(Icons.trending_down)),
                        ButtonSegment(
                            value: 'ingreso',
                            label: Text('Ingreso'),
                            icon: Icon(Icons.trending_up)),
                      ],
                      selected: {tipo},
                      onSelectionChanged: (s) {
                        setSt(() {
                          tipo = s.first;
                          categoriaId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: montoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Monto',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: categoriaId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: cats
                          .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.nombre),
                      ))
                          .toList(),
                      onChanged: (v) => setSt(() => categoriaId = v),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                          '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}'),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: fecha,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setSt(() => fecha = picked);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (d) => AlertDialog(
                                  title: const Text('Eliminar'),
                                  content: const Text('¿Eliminar esta transacción?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(d, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(d, true),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                final done = await txProv.delete(t.id);
                                if (done && ctx.mounted) {
                                  Navigator.pop(ctx);
                                  await reportProv.load();
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Guardar'),
                            onPressed: () async {
                              final monto = double.tryParse(
                                  montoCtrl.text.replaceAll(',', '.')) ??
                                  0;
                              if (monto <= 0 || categoriaId == null) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Monto > 0 y categoría obligatorios'),
                                  ),
                                );
                                return;
                              }
                              final done = await txProv.update(
                                id: t.id,
                                monto: monto,
                                descripcion: descCtrl.text.trim(),
                                tipo: tipo,
                                categoriaId: categoriaId!,
                                fecha: fecha,
                              );
                              if (done && ctx.mounted) {
                                Navigator.pop(ctx);
                                await reportProv.load();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _monthSelector(
      BuildContext context, {
        required int year,
        required int month,
        required VoidCallback onPrev,
        required VoidCallback onNext,
      }) {
    final scheme = Theme.of(context).colorScheme;
    final label = _monthNameEs(month) + ' $year';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
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

    final gradientColors = positive
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
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
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

  String _monthNameEs(int m) {
    const names = [
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    if (m < 1 || m > 12) return '$m';
    return names[m];
  }

  Color _hexToColor(String hex) {
    final v = hex.replaceAll('#', '');
    if (v.length != 6) return Colors.grey;
    return Color(int.parse('FF$v', radix: 16));
  }
}