import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import 'add_transaction_page.dart';
import 'categories_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final scheme = Theme.of(context).colorScheme;

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
              // Resumen financiero (3 tarjetas)
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: _summaryChip(
                          context,
                          title: 'Ingresos',
                          amount: tx.ingresosHoy,
                          color: Colors.green,
                          icon: Icons.trending_up,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryChip(
                          context,
                          title: 'Gastos',
                          amount: tx.gastosHoy,
                          color: Colors.red,
                          icon: Icons.trending_down,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryChip(
                          context,
                          title: 'Balance',
                          amount: tx.balanceHoy,
                          color: Colors.blue,
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Encabezado de lista + botón Agregar (Material 3)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Movimientos de hoy',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _goToAdd(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (tx.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (tx.today.isEmpty)
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            color: scheme.primary),
                        const SizedBox(height: 8),
                        const Text('No hay movimientos hoy'),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Registrar movimiento'),
                          onPressed: () => _goToAdd(context),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...tx.today.map((t) {
                  final isIngreso = t.tipo == 'ingreso';
                  final color = isIngreso ? Colors.green : Colors.red;
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: color.withOpacity(0.12),
                        child: Icon(
                          isIngreso ? Icons.add : Icons.remove,
                          color: color,
                        ),
                      ),
                      title: Text(
                        t.descripcion,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        t.fecha, // formato YYYY-MM-DD
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Text(
                        '${isIngreso ? '+' : '-'}Bs. ${t.monto.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {}, // futuro: detalle
                    ),
                  );
                }),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),

      // Botón flotante (Material 3) tipo "pill"
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _goToAdd(context),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 6,
      ),
    );
  }

  Widget _summaryChip(
      BuildContext context, {
        required String title,
        required double amount,
        required Color color,
        required IconData icon,
      }) {
    final scheme = Theme.of(context).colorScheme;
    final bg = color.withOpacity(0.08);
    final border = color.withOpacity(0.25);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                'Bs.',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}