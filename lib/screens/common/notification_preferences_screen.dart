import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:marcket_app/providers/user_profile_provider.dart';
import 'package:marcket_app/utils/theme.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _receiveEmailNotifications = true;
  bool _receivePushNotifications = true; // Placeholder for push notifications

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProfileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    _receiveEmailNotifications =
        userProfileProvider.currentUserModel?.receiveEmailNotifications ?? true;
    // Assuming push notifications might be managed elsewhere or default to true
    _receivePushNotifications = true;
  }

  Future<void> _updateNotificationPreferences() async {
    final userProfileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final currentUserModel = userProfileProvider.currentUserModel;

    if (currentUserModel == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error: No se pudo cargar el perfil del usuario.'),
            backgroundColor: AppTheme.error),
      );
      return;
    }

    try {
      await userProfileProvider.updateProfile(
        fullName: currentUserModel.fullName, // Keep existing fields
        receiveEmailNotifications: _receiveEmailNotifications,
        // Add other notification preferences here as they are implemented
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Preferencias de notificación actualizadas.'),
            backgroundColor: AppTheme.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al actualizar preferencias: $e'),
            backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferencias de Notificación'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title:
                  const Text('Recibir notificaciones por correo electrónico'),
              value: _receiveEmailNotifications,
              onChanged: (bool value) {
                setState(() {
                  _receiveEmailNotifications = value;
                });
                _updateNotificationPreferences();
              },
            ),
            SwitchListTile(
              title: const Text('Recibir notificaciones push'),
              value: _receivePushNotifications,
              onChanged: (bool value) {
                setState(() {
                  _receivePushNotifications = value;
                });
                // TODO: Implement actual push notification preference update
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Actualización de notificaciones push pendiente.')),
                );
              },
            ),
            // Add more notification preferences here
          ],
        ),
      ),
    );
  }
}
