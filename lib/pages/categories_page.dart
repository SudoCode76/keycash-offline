import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/category_provider.dart';
import '../data/models/category.dart';
import '../widgets/large_title_scaffold.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  String _filter = 'todos';
  bool _reorderMode = false;
  final _reorderScrollController = ScrollController();

  @override
  void dispose() {
    _reorderScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    final scheme = Theme.of(context).colorScheme;

    final list = provider.items.where((c) {
      if (_filter == 'todos') return true;
      return c.tipo == _filter;
    }).toList();

    // Cuando está en reordenar, usamos un Scaffold normal para aprovechar Expanded.
    if (_reorderMode) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Categorías'),
          actions: [
            IconButton(
              icon: const Icon(Icons.check_circle),
              tooltip: 'Salir de reordenar',
              onPressed: () => setState(() => _reorderMode = false),
            ),
          ],
        ),
        body: _buildReorderableView(context, provider),
      );
    }

    return LargeTitleScaffold(
      title: 'Categorías',
      size: TitleSize.compact,
      contentTopSpacing: 4,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Recargar',
          onPressed: () => context.read<CategoryProvider>().load(),
        ),
        IconButton(
          icon: const Icon(Icons.reorder),
          tooltip: 'Reordenar',
          onPressed: () => setState(() => _reorderMode = true),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Nueva categoría',
          onPressed: () => _openForm(context),
        ),
      ],
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Todos'),
              selected: _filter == 'todos',
              onSelected: (_) => setState(() => _filter = 'todos'),
            ),
            ChoiceChip(
              label: const Text('Ingresos'),
              selected: _filter == 'ingreso',
              onSelected: (_) => setState(() => _filter = 'ingreso'),
            ),
            ChoiceChip(
              label: const Text('Gastos'),
              selected: _filter == 'gasto',
              onSelected: (_) => setState(() => _filter = 'gasto'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...list.map((c) {
          final color = _hexToColor(c.color);
          return Card(
            elevation: 0,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: _buildIconWidget(c.icono, color, size: 18),
              ),
              title: Text(
                c.nombre,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                c.tipo == 'ingreso' ? 'Ingreso' : 'Gasto',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              trailing: Switch(
                value: c.activo,
                onChanged: (v) => provider.toggleActivo(c.id, v),
              ),
              onTap: () => _openForm(context, category: c),
              onLongPress: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar'),
                    content: Text('¿Eliminar "${c.nombre}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Eliminar'),
                      ),
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
          Card(
            color: scheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.error, color: scheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.error!,
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: scheme.onErrorContainer),
                    onPressed: () => context.read<CategoryProvider>().load(),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildReorderableView(BuildContext context, CategoryProvider provider) {
    final scheme = Theme.of(context).colorScheme;
    // Trabajamos con TODAS las categorías para ordenar globalmente.
    final items = provider.items.toList();
    return Column(
      children: [
        Material(
          color: scheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Arrastra para reordenar tus categorías. Se guarda automáticamente al soltar.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            onReorder: (oldIndex, newIndex) async {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = items.removeAt(oldIndex);
                items.insert(newIndex, item);
              });
              // Guardar orden
              await provider.reorder(items.map((e) => e.id).toList());
            },
            itemBuilder: (context, index) {
              final c = items[index];
              final color = _hexToColor(c.color);
              return Card(
                key: ValueKey(c.id),
                elevation: 0,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: _buildIconWidget(c.icono, color, size: 18),
                  ),
                  title: Text(
                    c.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    c.tipo == 'ingreso' ? 'Ingreso' : 'Gasto',
                    style: TextStyle(
                        color:
                        Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  trailing: ReorderableDragStartListener(
                    index: index,
                    child: Icon(Icons.drag_handle,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openForm(BuildContext context, {Category? category}) async {
    final provider = context.read<CategoryProvider>();

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: category?.nombre ?? '');
    String tipo = category?.tipo ?? 'gasto';
    String colorHex = category?.color ?? '#FF5722';
    String iconCode = category?.icono ?? 'mi:category';
    final isEdit = category != null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final insets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: insets.bottom),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final color = _hexToColor(colorHex);
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withOpacity(0.15),
                            child: _buildIconWidget(iconCode, color, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isEdit
                                ? 'Editar categoría'
                                : 'Nueva categoría',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.label_outline),
                        ),
                        validator: (v) => (v == null || v.trim().length < 3)
                            ? 'Mínimo 3 caracteres'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                              value: 'ingreso',
                              label: Text('Ingreso'),
                              icon: Icon(Icons.trending_up)),
                          ButtonSegment(
                              value: 'gasto',
                              label: Text('Gasto'),
                              icon: Icon(Icons.trending_down)),
                        ],
                        selected: {tipo},
                        onSelectionChanged: (s) =>
                            setModalState(() => tipo = s.first),
                      ),
                      const SizedBox(height: 12),
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Icono',
                          border:
                          OutlineInputBorder(borderSide: BorderSide.none),
                          filled: true,
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _iconCatalog.entries.map((e) {
                            final selected = iconCode == e.key;
                            return InkWell(
                              onTap: () =>
                                  setModalState(() => iconCode = e.key),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.12)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: selected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: _buildIconWidget(e.key,
                                    _hexToColor(colorHex),
                                    size: 20),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Color',
                          border:
                          OutlineInputBorder(borderSide: BorderSide.none),
                          filled: true,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _presetColors.map((h) {
                                final selected = colorHex.toUpperCase() ==
                                    h.toUpperCase();
                                return InkWell(
                                  onTap: () =>
                                      setModalState(() => colorHex = h),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: _hexToColor(h),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selected
                                            ? Colors.black87
                                            : Colors.white,
                                        width: selected ? 2 : 1,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: colorHex,
                              decoration: const InputDecoration(
                                hintText: '#RRGGBB',
                                prefixIcon:
                                Icon(Icons.color_lens_outlined),
                              ),
                              onChanged: (v) =>
                                  setModalState(() => colorHex = v.trim()),
                              validator: (v) => _isValidHex(v ?? '')
                                  ? null
                                  : 'Hex inválido (ej: #FF5722)',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (isEdit)
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                label: const Text(
                                  'Eliminar',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (d) => AlertDialog(
                                      title: const Text('Eliminar'),
                                      content: Text(
                                          '¿Eliminar la categoría "${category!.nombre}"?'),
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
                                    await provider.delete(category.id);
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  }
                                },
                              ),
                            ),
                          if (isEdit) const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              icon: const Icon(Icons.save),
                              label:
                              Text(isEdit ? 'Guardar' : 'Crear'),
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }
                                bool ok;
                                if (isEdit) {
                                  ok = await provider.updateCategory(
                                    category!,
                                    nombre: nameCtrl.text,
                                    tipo: tipo,
                                    color: colorHex,
                                    icono: iconCode,
                                  );
                                } else {
                                  ok = await provider.add(
                                    nombre: nameCtrl.text,
                                    tipo: tipo,
                                    color: colorHex,
                                    icono: iconCode,
                                  );
                                }
                                if (ok && ctx.mounted) Navigator.pop(ctx);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  static const Map<String, _IconSpec> _iconCatalog = {
    // Material
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
    // FontAwesome
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

  static const List<String> _presetColors = [
    '#4CAF50', '#00BCD4', '#795548', '#FF5722', '#2196F3',
    '#9C27B0', '#FF9800', '#F44336', '#607D8B', '#3F51B5',
  ];

  Widget _buildIconWidget(String code, Color color, {double size = 20}) {
    final spec = _parseIcon(code);
    if (spec.isFa) return FaIcon(spec.data, color: color, size: size);
    return Icon(spec.data, color: color, size: size);
  }

  _IconSpec _parseIcon(String code) {
    if (!_iconCatalog.containsKey(code)) {
      final fallbackKey = 'mi:$code';
      return _iconCatalog[fallbackKey] ?? const _IconSpec.mi(Icons.category);
    }
    return _iconCatalog[code]!;
  }

  static bool _isValidHex(String s) {
    final v = s.trim().toUpperCase();
    final reg = RegExp(r'^#([A-F0-9]{6})$');
    return reg.hasMatch(v);
  }

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