import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // Removed
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class WelcomeDashboardScreen extends StatefulWidget {
  const WelcomeDashboardScreen({super.key});

  @override
  State<WelcomeDashboardScreen> createState() => _WelcomeDashboardScreenState();
}

class _WelcomeDashboardScreenState extends State<WelcomeDashboardScreen> {
  UserModel? _currentUserModel;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseDatabase.instance.ref('users/${user.uid}').get();
      if (snapshot.exists && snapshot.value is Map && mounted) {
        setState(() {
          final Map<dynamic, dynamic> rawData = snapshot.value as Map<dynamic, dynamic>;
          _currentUserModel = UserModel.fromMap(
            Map<String, dynamic>.from(rawData),
            user.uid,
          );
        });
      }
    }
  }

  String _getTranslatedRole(String? userType) {
    switch (userType) {
      case 'Buyer':
        return 'Comprador';
      case 'Seller':
        return 'Vendedor';
      case 'Admin':
        return 'Administrador';
      default:
        return 'Rol Desconocido';
    }
  }

  String _getGreeting() {
    if (_currentUserModel?.gender == 'Female') { // Assuming 'Female' for women
      return 'Bienvenida';
    } else if (_currentUserModel?.gender == 'Male') { // Assuming 'Male' for men
      return 'Bienvenido';
    }
    return 'Bienvenido/a'; // Default neutral greeting
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // No AppBar, ResponsiveScaffold will provide it
      body: _currentUserModel == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getGreeting()} a Manos del Mar', // Use greeting here
                    style: textTheme.headlineMedium?.copyWith(
                        color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
                  const SizedBox(height: 10),
                  Text(
                    'Usuario: ${_currentUserModel?.fullName ?? user?.displayName ?? 'Invitado'}',
                    style: textTheme.titleLarge,
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.2),
                  Text(
                    'Rol: ${_getTranslatedRole(_currentUserModel?.userType)}',
                    style: textTheme.titleMedium,
                  ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.2),
                  Text(
                    'Correo: ${user?.email ?? 'N/A'}',
                    style: textTheme.titleMedium,
                  ).animate().fadeIn(delay: 600.ms, duration: 600.ms).slideY(begin: 0.2),
                  const SizedBox(height: 30),

                  Text(
                    'Explora lo nuevo de nuestra app:',
                    style: textTheme.headlineSmall?.copyWith(
                        color: AppTheme.secondary, fontWeight: FontWeight.bold),
                  ).animate().fadeIn(delay: 800.ms, duration: 600.ms).slideY(begin: 0.2),
                  const SizedBox(height: 20),

                  // Placeholder for animated cards
                  _buildAnimatedCard(
                    context,
                    title: 'Descubre Productos Frescos',
                    description: 'Encuentra productos únicos de artesanos y pescadores locales.',
                    icon: Icons.local_mall,
                    delay: 1000.ms,
                  ),
                  _buildAnimatedCard(
                    context,
                    title: 'Mantente al día con Publicaciones',
                    description: 'Explora las últimas novedades y creaciones de tus vendedores favoritos.',
                    icon: Icons.video_collection,
                    delay: 1200.ms,
                  ),
                  _buildAnimatedCard(
                    context,
                    title: 'Gestiona tus Pedidos',
                    description: 'Un seguimiento detallado de tus compras y ventas.',
                    icon: Icons.delivery_dining,
                    delay: 1400.ms,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAnimatedCard(BuildContext context, {required String title, required String description, required IconData icon, required Duration delay}) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: AppTheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay, duration: 600.ms).slideX(begin: 0.1);
  }
}
