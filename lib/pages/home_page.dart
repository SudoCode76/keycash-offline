import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import 'add_transaction_page.dart';
import 'categories_page.dart';
import 'reports_page.dart';
import '../data/models/transaction.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _goToAdd(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddTransactionPage()),
    );
    if (context.mounted) {
      await context.read<TransactionProvider>().loadToday();
    }
  }

  void _openEditTransactionSheet(BuildContext context, TransactionModel t) {
    final txProv = context.read<TransactionProvider>();
    final catProv = context.read<CategoryProvider>();
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
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            label: const Text('Eliminar',
                                style: TextStyle(color: Colors.red)),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (d) => AlertDialog(
                                  title: const Text('Eliminar'),
                                  content: const Text(
                                      '¿Eliminar esta transacción?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(d, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(d, true),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                final done = await txProv.delete(t.id);
                                if (done && ctx.mounted) Navigator.pop(ctx);
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
                                    content: Text(
                                        'Monto > 0 y categoría obligatorios'),
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
                              if (done && ctx.mounted) Navigator.pop(ctx);
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

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final cats = context.watch<CategoryProvider>().items;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: const Text('KeyCash Offline'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Categorías',
            icon: const Icon(Icons.category_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoriesPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<TransactionProvider>().loadToday(),
          color: scheme.primary,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _balanceCard(context, tx.balanceHoy),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _miniStatCard(
                      context,
                      title: 'Ingresos',
                      amount: tx.ingresosHoy,
                      color: Colors.green,
                      icon: Icons.arrow_upward_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _miniStatCard(
                      context,
                      title: 'Gastos',
                      amount: tx.gastosHoy,
                      color: Colors.red,
                      icon: Icons.arrow_downward_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Movimientos recientes',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ReportsPage()),
                      );
                    },
                    child: const Text('Ver todo'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (tx.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (tx.today.isEmpty)
                _emptyState(context)
              else
                ...tx.today.map((t) {
                  final isIngreso = t.tipo == 'ingreso';
                  final color = isIngreso ? Colors.green : Colors.red;
                  final matches = cats.where((c) => c.id == t.categoriaId);
                  final cat = matches.isNotEmpty ? matches.first : null;
                  final iconWidget = cat != null
                      ? _buildIconWidget(cat.icono, _hexToColor(cat.color))
                      : Icon(isIngreso ? Icons.add : Icons.remove,
                      color: color);

                  final titulo =
                      cat?.nombre ?? (isIngreso ? 'Ingreso' : 'Gasto');

                  final subtitulo =
                      '${isIngreso ? 'Ingreso' : 'Gasto'} · ${t.fecha}';

                  return Card(
                    elevation: 1,
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : scheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.06),
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: (isIngreso
                            ? Colors.green
                            : Colors.red)
                            .withOpacity(isDark ? 0.20 : 0.12),
                        child: iconWidget,
                      ),
                      title: Text(
                        titulo,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        subtitulo,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      trailing: Text(
                        '${isIngreso ? '+' : '-'}Bs. ${t.monto.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => _openEditTransactionSheet(context, t),
                    ),
                  );
                }),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _goToAdd(context),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }

  Widget _balanceCard(BuildContext context, double balance) {
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : scheme.primary)
                .withOpacity(isDark ? 0.35 : 0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu balance',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bs. ${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // FIX: color de texto para modo claro (antes quedaba blanco también)
  Widget _miniStatCard(
      BuildContext context, {
        required String title,
        required double amount,
        required Color color,
        required IconData icon,
      }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? color.withOpacity(0.16) : color.withOpacity(0.12);
    final badgeBg =
    isDark ? Colors.white.withOpacity(0.08) : color.withOpacity(0.12);
    final border = isDark ? color.withOpacity(0.35) : color.withOpacity(0.22);

    final titleColor =
    isDark ? Colors.white.withOpacity(0.85) : scheme.onSurface; // negro / onSurface en claro

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: badgeBg,
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
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bs. ${amount.toStringAsFixed(2)}',
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

  Widget _emptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 1,
      color: isDark ? Colors.white.withOpacity(0.05) : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, color: scheme.primary),
            const SizedBox(height: 8),
            const Text('No hay movimientos hoy'),
            const SizedBox(height: 12),
            Text(
              'Toca el botón Agregar para registrar tu primer movimiento.',
              style: TextStyle(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconWidget(String code, Color color, {double size = 20}) {
    final spec = _parseIcon(code);
    if (spec.isFa) {
      return FaIcon(spec.data, color: color, size: size);
    }
    return Icon(spec.data, color: color, size: size);
  }

  _IconSpec _parseIcon(String code) {
    if (!_iconCatalog.containsKey(code)) {
      final fallbackKey = 'mi:$code';
      return _iconCatalog[fallbackKey] ?? const _IconSpec.mi(Icons.category);
    }
    return _iconCatalog[code]!;
  }

  static const Map<String, _IconSpec> _iconCatalog = {
    'mi:category': _IconSpec.mi(Icons.category),
    'mi:restaurant': _IconSpec.mi(Icons.restaurant),
    'mi:directions_car': _IconSpec.mi(Icons.directions_car),
    'mi:local_hospital': _IconSpec.mi(Icons.local_hospital),
    'mi:receipt': _IconSpec.mi(Icons.receipt),
    'mi:movie': _IconSpec.mi(Icons.movie),
    'mi:work': _IconSpec.mi(Icons.work),
    'mi:computer': _IconSpec.mi(Icons.computer),
    'mi:trending_up': _IconSpec.mi(Icons.trending_up),
    'mi:trending_down': _IconSpec.mi(Icons.trending_down),
    'mi:shopping_cart': _IconSpec.mi(Icons.shopping_cart),
    'mi:home': _IconSpec.mi(Icons.home),
    'mi:sports_esports': _IconSpec.mi(Icons.sports_esports),
    'fa:utensils': _IconSpec.fa(FontAwesomeIcons.utensils),
    'fa:cartShopping': _IconSpec.fa(FontAwesomeIcons.cartShopping),
    'fa:car': _IconSpec.fa(FontAwesomeIcons.car),
    'fa:house': _IconSpec.fa(FontAwesomeIcons.house),
    'fa:stethoscope': _IconSpec.fa(FontAwesomeIcons.stethoscope),
    'fa:fileInvoice': _IconSpec.fa(FontAwesomeIcons.fileInvoiceDollar),
    'fa:film': _IconSpec.fa(FontAwesomeIcons.film),
    'fa:briefcase': _IconSpec.fa(FontAwesomeIcons.briefcase),
    'fa:laptopCode': _IconSpec.fa(FontAwesomeIcons.laptopCode),
    'fa:chartLine': _IconSpec.fa(FontAwesomeIcons.chartLine),
    'fa:piggyBank': _IconSpec.fa(FontAwesomeIcons.piggyBank),
    'fa:gamepad': _IconSpec.fa(FontAwesomeIcons.gamepad),
  };

  static Color _hexToColor(String hex) {
    final v = hex.replaceAll('#', '');
    if (v.length != 6) return Colors.grey;
    return Color(int.parse('FF$v', radix: 16));
  }
}

class _IconSpec {
  final bool isFa;
  final IconData data;
  const _IconSpec._(this.isFa, this.data);
  const _IconSpec.mi(IconData d) : this._(false, d);
  const _IconSpec.fa(IconData d) : this._(true, d);
}