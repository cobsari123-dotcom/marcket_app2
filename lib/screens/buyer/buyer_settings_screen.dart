import 'package:flutter/material.dart';
import 'package:marcket_app/screens/common/notification_preferences_screen.dart'; // New import
import 'package:marcket_app/screens/common/privacy_settings_screen.dart'; // New import

class BuyerSettingsScreen extends StatelessWidget {
  const BuyerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración del Comprador'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preferencias Generales',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Tema de la Aplicación'),
                subtitle: const Text('Cambiar entre tema claro y oscuro'),
                onTap: () {
                  // TODO: Implement theme change logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funcionalidad de tema pendiente')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Idioma'),
                subtitle: const Text('Seleccionar idioma de la aplicación'),
                onTap: () {
                  // TODO: Implement language change logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funcionalidad de idioma pendiente')),
                  );
                },
              ),
              const Divider(),
              Text(
                'Privacidad y Seguridad',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Cambiar Contraseña'),
                onTap: () {
                  // TODO: Implement change password logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funcionalidad de cambio de contraseña pendiente')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Gestionar Métodos de Pago'),
                onTap: () {
                  // TODO: Implement payment method management logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funcionalidad de gestión de pagos pendiente')),
                  );
                },
              ),
              ListTile( // New
                leading: const Icon(Icons.notifications),
                title: const Text('Preferencias de Notificación'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPreferencesScreen()));
                },
              ),
              ListTile( // New
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Configuración de Privacidad'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacySettingsScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
