import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  String _filter = 'todos'; // todos | ingreso | gasto

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    final list = provider.items.where((c) {
      if (_filter == 'todos') return true;
      return c.tipo == _filter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<CategoryProvider>().load(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(context),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(label: const Text('Todos'), selected: _filter == 'todos', onSelected: (_) => setState(() => _filter = 'todos')),
              ChoiceChip(label: const Text('Ingresos'), selected: _filter == 'ingreso', onSelected: (_) => setState(() => _filter = 'ingreso')),
              ChoiceChip(label: const Text('Gastos'), selected: _filter == 'gasto', onSelected: (_) => setState(() => _filter = 'gasto')),
            ],
          ),
          const SizedBox(height: 8),
          ...list.map((c) {
            final color = _hexToColor(c.color);
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(Icons.category, color: color),
                ),
                title: Text(c.nombre),
                subtitle: Text(c.tipo),
                trailing: Switch(
                  value: c.activo,
                  onChanged: (v) => provider.toggleActivo(c.id, v),
                ),
                onLongPress: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Eliminar'),
                      content: Text('¿Eliminar "${c.nombre}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
                      ],
                    ),
                  );
                  if (ok == true) await provider.delete(c.id);
                },
              ),
            );
          }),
          if (provider.error != null) ...[
            const SizedBox(height: 8),
            Text(provider.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    String tipo = 'gasto';
    String color = '#FF5722';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        final insets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: insets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Nueva categoría', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.label_outline)),
                    validator: (v) => (v == null || v.trim().length < 3) ? 'Mínimo 3 caracteres' : null,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'ingreso', label: Text('Ingreso'), icon: Icon(Icons.trending_up)),
                      ButtonSegment(value: 'gasto', label: Text('Gasto'), icon: Icon(Icons.trending_down)),
                    ],
                    selected: {tipo},
                    onSelectionChanged: (s) => setState(() => tipo = s.first),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: color,
                    decoration: const InputDecoration(labelText: 'Color (#RRGGBB)', prefixIcon: Icon(Icons.color_lens_outlined)),
                    onChanged: (v) => color = v.trim(),
                    validator: (v) => _isValidHex(v ?? '') ? null : 'Hex inválido (ej: #FF5722)',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final ok = await context.read<CategoryProvider>().add(
                        nombre: nameCtrl.text,
                        tipo: tipo,
                        color: color,
                        icono: 'category',
                      );
                      if (ok && mounted) Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isValidHex(String s) {
    final v = s.trim().toUpperCase();
    final reg = RegExp(r'^#([A-F0-9]{6})$');
    return reg.hasMatch(v);
  }

  Color _hexToColor(String hex) {
    final v = hex.replaceAll('#', '');
    if (v.length != 6) return Colors.grey;
    return Color(int.parse('FF$v', radix: 16));
  }
}