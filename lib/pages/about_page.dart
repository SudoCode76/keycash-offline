import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/large_title_scaffold.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static final Uri _whatsUri = Uri.parse(
      'https://wa.me/59178466952?text=Hola,%20estoy%20interesado%20en%20el%20código%20fuente%20de%20KeyCash');

  Future<void> _launchWhatsApp(BuildContext context) async {
    if (!await launchUrl(_whatsUri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No se pudo abrir WhatsApp. Asegúrate de tener WhatsApp instalado, o prueba en un dispositivo real.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LargeTitleScaffold(
      title: 'Acerca de',
      size: TitleSize.compact,
      contentTopSpacing: 4,
      children: [
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Acerca de KeyCash',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: scheme.primary.withOpacity(0.15),
                    child: const Icon(Icons.badge_outlined, color: Colors.green),
                  ),
                  title: const Text('Desarrollador'),
                  subtitle: const Text('Miguel Angel Zenteno Orellana'),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: scheme.secondary.withOpacity(0.15),
                    child: const Icon(Icons.developer_mode, color: Colors.blue),
                  ),
                  title: const Text('Tecnologías utilizadas'),
                  subtitle: const Text('Stack principal de la aplicación'),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _TechChip('Flutter 3 (Material 3)'),
                    _TechChip('Dart'),
                    _TechChip('Provider'),
                    _TechChip('Google Generative AI (Gemini)'),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scheme.secondary.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.code, color: scheme.secondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '¿Interesado en el código fuente?\nContáctame por WhatsApp y te comparto los detalles.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _launchWhatsApp(context),
                        icon: FaIcon(
                          FontAwesomeIcons.whatsapp,
                          color: Colors.green,
                          size: 20,
                        ),
                        label: const Text('WhatsApp'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.secondary,
                          side: BorderSide(color: scheme.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _TechChip extends StatelessWidget {
  final String label;
  const _TechChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor:
      Theme.of(context).colorScheme.primary.withOpacity(0.08),
      labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w500),
    );
  }
}