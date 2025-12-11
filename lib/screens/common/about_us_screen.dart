import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:marcket_app/utils/theme.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre Nosotros'),
        automaticallyImplyLeading: false, // Remove default back button
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nuestra Historia',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Manos del Mar nació de la pasión por la innovación y el deseo de conectar a artesanos, pequeños comerciantes y emprendedores con una audiencia más amplia. La idea surgió de un profundo análisis de las necesidades del mercado local, buscando crear una plataforma intuitiva y atractiva donde los productos únicos pudieran brillar.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Text(
                  'Nuestros Creadores',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Esta aplicación fue concebida y desarrollada por un dedicado grupo de alumnos de la Universidad Tecnológica de Campeche, de la carrera de Ingeniería en Desarrollo y Gestión de Software. Con creatividad, esfuerzo y conocimientos técnicos, hemos transformado una visión en esta plataforma digital que hoy tienes en tus manos.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Text(
                  'Nuestra Misión',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Manos del Mar busca ser el puente entre el talento local y los consumidores, fomentando el comercio justo, la economía creativa y la valoración del trabajo artesanal y emprendedor. Creemos en el poder de la tecnología para empoderar a las comunidades y ofrecer productos con historias que inspiran.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                Text(
                  'Contáctanos',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondary,
                      ),
                ),
                const Divider(height: 24),
                _buildContactTile(
                  context,
                  icon: Icons.email,
                  title: 'Correo Electrónico',
                  subtitle: 'marcket37@gmail.com',
                  onTap: () => _launchURL('mailto:marcket37@gmail.com'),
                ),
                _buildContactTile(
                  context,
                  icon: FontAwesomeIcons.whatsapp,
                  title: 'WhatsApp',
                  subtitle: '+52 1 938 120 6626',
                  onTap: () => _launchURL('https://wa.me/5219381206626'),
                ),
                _buildContactTile(
                  context,
                  icon: FontAwesomeIcons.facebook,
                  title: 'Facebook',
                  subtitle: 'Manos del Mar',
                  onTap: () =>
                      _launchURL('https://www.facebook.com/share/17eFyLMNQH/'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary, size: 28),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        onTap: onTap,
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      debugPrint('No se pudo lanzar $url');
      // Optionally show a SnackBar
    }
  }
}
