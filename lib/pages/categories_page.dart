import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
    final scheme = Theme.of(context).colorScheme;

    final list = provider.items.where((c) {
      if (_filter == 'todos') return true;
      return c.tipo == _filter;
    }).toList();

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: () => context.read<CategoryProvider>().load(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nueva categoría',
            onPressed: () => _openForm(context),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () => context.read<CategoryProvider>().load(),
        color: scheme.primary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Filtros
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

            // Lista
            ...list.map((c) {
              final color = _hexToColor(c.color);
              return Card(
                elevation: 1,
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
        ),
      ),

      // Botón flotante para agregar (Material 3)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }

  Future<void> _openForm(BuildContext context) async {
    final provider = context.read<CategoryProvider>();

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    String tipo = 'gasto';
    String colorHex = '#FF5722';
    String iconCode = 'mi:category'; // prefijo: mi (Material) | fa (FontAwesome)

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
        final scheme = Theme.of(ctx).colorScheme;

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
                      // Header con icono seleccionado
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withOpacity(0.15),
                            child: _buildIconWidget(iconCode, color, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Nueva categoría',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Nombre
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

                      // Tipo (Ingreso / Gasto)
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

                      // Selección de ícono (Material + FontAwesome)
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Icono',
                          border: OutlineInputBorder(
                              borderSide: BorderSide.none),
                          filled: true,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _iconCatalog.entries.map((e) {
                                final selected = iconCode == e.key;
                                final bg = selected
                                    ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.12)
                                    : Colors.transparent;
                                final border = selected
                                    ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    : Colors.grey.shade300;

                                return InkWell(
                                  onTap: () => setModalState(
                                          () => iconCode = e.key),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: bg,
                                      border: Border.all(color: border),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: _buildIconWidget(
                                      e.key,
                                      _hexToColor(colorHex),
                                      size: 20,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Color (hex manual + preset)
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Color',
                          border: OutlineInputBorder(
                              borderSide: BorderSide.none),
                          filled: true,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _presetColors.map((h) {
                                final selected =
                                    colorHex.toUpperCase() ==
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

                      // Acciones
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close),
                              label: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }
                                final ok = await provider.add(
                                  nombre: nameCtrl.text,
                                  tipo: tipo,
                                  color: colorHex,
                                  icono: iconCode, // guarda código con prefijo
                                );
                                if (ok && mounted) Navigator.pop(ctx);
                              },
                              icon: const Icon(Icons.save),
                              label: const Text('Guardar'),
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

  // ========= Helpers =========

  // Catálogo de iconos (mi:* = Material, fa:* = FontAwesome)
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

    // FontAwesome (usar FaIcon para render)
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
    if (spec.isFa) {
      return FaIcon(spec.data, color: color, size: size);
    }
    return Icon(spec.data, color: color, size: size);
  }

  _IconSpec _parseIcon(String code) {
    // Si viene sin prefijo, asumir material
    if (!_iconCatalog.containsKey(code)) {
      final fallbackKey = 'mi:$code'; // ej: "category" -> "mi:category"
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