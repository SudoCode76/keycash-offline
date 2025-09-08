import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Reportes Mensuales'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Próximamente: Reportes (offline)'),
      ),
    );
  }
}