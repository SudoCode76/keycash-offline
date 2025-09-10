import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _descCtrl = TextEditingController(); // ahora opcional
  String _tipo = 'gasto';
  String? _categoriaId;
  DateTime _fecha = DateTime.now();

  @override
  void dispose() {
    _montoCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = context
        .watch<CategoryProvider>()
        .items
        .where((c) => c.activo && c.tipo == _tipo)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Agregar movimiento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
                selected: {_tipo},
                onSelectionChanged: (s) => setState(() {
                  _tipo = s.first;
                  _categoriaId = null;
                }),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _montoCtrl,
                decoration: const InputDecoration(
                    labelText: 'Monto', prefixIcon: Icon(Icons.attach_money)),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final d = double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (d == null || d <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Descripción OPCIONAL
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                // sin validator => puede ser vacío
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _categoriaId,
                decoration: const InputDecoration(
                    labelText: 'Categoría', prefixIcon: Icon(Icons.category)),
                isExpanded: true,
                items: cats
                    .map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text('${c.nombre} (${c.tipo})'),
                ))
                    .toList(),
                onChanged: (v) => setState(() => _categoriaId = v),
                validator: (v) =>
                v == null ? 'Selecciona una categoría' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(
                    '${_fecha.year}-${_fecha.month.toString().padLeft(2, '0')}-${_fecha.day.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.edit_calendar),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _fecha,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _fecha = picked);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    final ok = await context.read<TransactionProvider>().add(
                      monto: double.parse(
                          _montoCtrl.text.replaceAll(',', '.')),
                      descripcion:
                      _descCtrl.text.trim(), // puede ir vacío
                      tipo: _tipo,
                      categoriaId: _categoriaId!,
                      fecha: _fecha,
                    );
                    if (ok && mounted) Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}