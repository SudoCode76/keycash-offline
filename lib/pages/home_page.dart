import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import 'add_transaction_page.dart';
import 'categories_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('KeyCash Offline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoriesPage()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<TransactionProvider>().loadToday(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _tile('Ingresos', tx.ingresosHoy, Colors.green),
                    const SizedBox(width: 12),
                    _tile('Gastos', tx.gastosHoy, Colors.red),
                    const SizedBox(width: 12),
                    _tile('Balance', tx.balanceHoy, tx.balanceHoy >= 0 ? Colors.blue : Colors.orange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Movimientos de hoy', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (tx.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (tx.today.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 8),
                      const Text('Sin movimientos hoy'),
                    ],
                  ),
                ),
              )
            else
              ...tx.today.map((t) {
                final isIngreso = t.tipo == 'ingreso';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (isIngreso ? Colors.green : Colors.red).withOpacity(0.1),
                      child: Icon(isIngreso ? Icons.add : Icons.remove,
                          color: isIngreso ? Colors.green : Colors.red),
                    ),
                    title: Text(t.descripcion),
                    subtitle: Text(t.fecha),
                    trailing: Text(
                      '${isIngreso ? '+' : '-'}Bs. ${t.monto.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isIngreso ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            if (tx.error != null) ...[
              const SizedBox(height: 8),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Theme.of(context).colorScheme.onErrorContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tx.error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onErrorContainer),
                        onPressed: () => context.read<TransactionProvider>().clearError(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddTransactionPage()));
          if (context.mounted) context.read<TransactionProvider>().loadToday();
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }

  Expanded _tile(String title, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text('Bs. ${value.toStringAsFixed(2)}',
                style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}