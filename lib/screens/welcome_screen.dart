import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:marcket_app/utils/theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.verdeAguaSuave],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700), // Limit overall width
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: size.height * 0.05),
                      Image.asset(
                        'assets/images/logoapp.jpg',
                        height: size.height * 0.15,
                        fit: BoxFit.contain,
                      ).animate().fade(duration: 1000.ms).slideY(begin: -1, curve: Curves.easeOut),
                      const SizedBox(height: 20),
                      Text(
                        'Manos del Mar',
                        style: textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontSize: size.width > 600 ? 70.0 : 50.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fade(delay: 500.ms, duration: 1000.ms),
                      const SizedBox(height: 10.0),
                      Text(
                        'Conectando artesanos y pescadores locales con el mundo',
                        textAlign: TextAlign.center,
                        style: textTheme.titleLarge?.copyWith(
                          color: Colors.white.withAlpha(229), // Fixed deprecated
                          fontSize: size.width > 600 ? 28.0 : 22.0,
                          fontWeight: FontWeight.w300,
                        ),
                      ).animate().fade(delay: 800.ms, duration: 1000.ms),
                      SizedBox(height: size.height * 0.08),
                      _buildFeaturesSection(context),
                      SizedBox(height: size.height * 0.08),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Empezar'),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward),
                          ],
                        ),
                      ).animate().scale(delay: 1200.ms, duration: 600.ms, curve: Curves.elasticOut),
                      SizedBox(height: size.height * 0.05),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Column(
      children: [
        FeatureCard( // Renamed
          icon: Icons.connect_without_contact,
          title: 'Conecta',
          description: 'Comunícate directamente con artesanos y pescadores locales.',
          delay: 1000.ms,
        ),
        const SizedBox(height: 20),
        FeatureCard( // Renamed
          icon: Icons.explore,
          title: 'Descubre',
          description: 'Explora productos únicos y auténticos, llenos de historia y tradición.',
          delay: 1200.ms,
        ),
        const SizedBox(height: 20),
        FeatureCard( // Renamed
          icon: Icons.favorite,
          title: 'Apoya',
          description: 'Contribuye al comercio justo y al desarrollo de la economía local de Campeche.',
          delay: 1400.ms,
        ),
      ],
    );
  }
}

class FeatureCard extends StatelessWidget { // Renamed
  final IconData icon;
  final String title;
  final String description;
  final Duration delay;

  const FeatureCard({ // Renamed
    super.key, // Added key
    required this.icon,
    required this.title,
    required this.description,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 40, color: Colors.white),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withAlpha(229), // Fixed deprecated
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fade(delay: delay, duration: 800.ms).slideX(begin: -0.5);
  }
}