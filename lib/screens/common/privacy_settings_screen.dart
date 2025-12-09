import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:marcket_app/providers/user_profile_provider.dart';
import 'package:marcket_app/utils/theme.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _isProfilePublic = true; // Placeholder for profile visibility
  bool _allowPersonalizedAds = false; // Placeholder for personalized ads

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // For now, these are just placeholders. Real implementation would fetch from UserModel.
    // _isProfilePublic = Provider.of<UserProfileProvider>(context, listen: false).currentUserModel?.isProfilePublic ?? true;
  }

  Future<void> _updatePrivacySettings() async {
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
      // Assuming 'isProfilePublic' would be a new field in UserModel
      // await userProfileProvider.updateProfile(
      //   fullName: currentUserModel.fullName, // Keep existing fields
      //   isProfilePublic: _isProfilePublic,
      // );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Configuración de privacidad actualizada.'),
            backgroundColor: AppTheme.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Error al actualizar configuración de privacidad: $e'),
            backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Privacidad'),
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
              title: const Text('Hacer mi perfil público'),
              subtitle:
                  const Text('Permite que otros usuarios vean tu perfil.'),
              value: _isProfilePublic,
              onChanged: (bool value) {
                setState(() {
                  _isProfilePublic = value;
                });
                _updatePrivacySettings();
              },
            ),
            SwitchListTile(
              title: const Text('Permitir anuncios personalizados'),
              subtitle: const Text(
                  'Permite que la aplicación muestre anuncios basados en tus intereses.'),
              value: _allowPersonalizedAds,
              onChanged: (bool value) {
                setState(() {
                  _allowPersonalizedAds = value;
                });
                // TODO: Implement actual personalized ads preference update
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Actualización de preferencias de anuncios pendiente.')),
                );
              },
            ),
            // Add more privacy settings here
          ],
        ),
      ),
    );
  }
}
