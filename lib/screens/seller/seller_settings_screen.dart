// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/providers/theme_provider.dart'; 
import 'package:marcket_app/providers/user_profile_provider.dart';
import 'package:marcket_app/services/auth_management_service.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:marcket_app/screens/common/notification_preferences_screen.dart'; 
import 'package:marcket_app/screens/common/privacy_settings_screen.dart'; 
import 'package:provider/provider.dart';

// --- CORRECCIÓN: Se agregó la definición de la clase que faltaba ---
class SellerSettingsScreen extends StatefulWidget {
  const SellerSettingsScreen({super.key});

  @override
  State<SellerSettingsScreen> createState() => SellerSettingsScreenState();
}

class SellerSettingsScreenState extends State<SellerSettingsScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();
  final TextEditingController _newEmailController = TextEditingController();
  final TextEditingController _confirmNewEmailController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessAddressController = TextEditingController();
  final TextEditingController _paymentInstructionsController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmNewPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    _newEmailController.dispose();
    _confirmNewEmailController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _paymentInstructionsController.dispose();
    super.dispose();
  }

  void _populateControllers(UserModel? userModel) {
    if (userModel != null) {
      _businessNameController.text = userModel.businessName ?? '';
      _businessAddressController.text = userModel.businessAddress ?? '';
      _paymentInstructionsController.text = userModel.paymentInstructions ?? '';
    }
  }

  Future<bool> _showReauthenticateDialog(AuthManagementService authManagementService) async {
    _currentPasswordController.clear();
    bool? reauthenticated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Reautenticación Requerida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Por favor, ingresa tu contraseña actual para continuar.'),
            const SizedBox(height: 16),
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña Actual'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                await authManagementService.reauthenticateUser(
                  FirebaseAuth.instance.currentUser!.email!,
                  _currentPasswordController.text,
                );
                if (mounted) Navigator.of(context).pop(true);
              } on FirebaseAuthException catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Error de reautenticación: ${e.message}'),
                  backgroundColor: AppTheme.error,
                  duration: Duration(seconds: 3),
                ));
                if (!mounted) return;
                Navigator.of(context).pop(false);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Error desconocido de reautenticación: $e'),
                  backgroundColor: AppTheme.error,
                  duration: Duration(seconds: 3),
                ));
                if (!mounted) return;
                Navigator.of(context).pop(false);
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return reauthenticated ?? false;
  }

  Future<void> _updatePassword(AuthManagementService authManagementService, UserProfileProvider userProfileProvider) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || userProfileProvider.currentUserModel?.userType == 'Google') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes cambiar la contraseña para usuarios de Google.'),
          backgroundColor: AppTheme.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    bool reauthenticated = await _showReauthenticateDialog(authManagementService);
    if (!mounted) return;
    if (!reauthenticated) return;

    _newPasswordController.clear();
    _confirmNewPasswordController.clear();
    
    if(!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder( 
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Actualizar Contraseña'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setStateDialog(() => _obscureNewPassword = !_obscureNewPassword);
                      },
                    ),
                  ),
                ),
                TextField(
                  controller: _confirmNewPasswordController,
                  obscureText: _obscureConfirmNewPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Nueva Contraseña',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmNewPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setStateDialog(() => _obscureConfirmNewPassword = !_obscureConfirmNewPassword);
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  if (_newPasswordController.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('La contraseña debe tener al menos 6 caracteres.'),
                        backgroundColor: AppTheme.error,
                        duration: Duration(seconds: 3),
                      ),
                    );
                    return;
                  }
                  if (_newPasswordController.text != _confirmNewPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Las contraseñas no coinciden.'),
                        backgroundColor: AppTheme.error,
                        duration: Duration(seconds: 3),
                      ),
                    );
                    return;
                  }

                  try {
                    await authManagementService.updatePassword(_newPasswordController.text);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contraseña actualizada exitosamente.'), backgroundColor: AppTheme.success, duration: Duration(seconds: 3)),
                    );
                    Navigator.of(context).pop();
                  } on FirebaseAuthException catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error al actualizar contraseña: ${e.message}'),
                      backgroundColor: AppTheme.error,
                      duration: Duration(seconds: 3),
                    ));
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error desconocido al actualizar contraseña: $e'),
                      backgroundColor: AppTheme.error,
                      duration: Duration(seconds: 3),
                    ));
                  }
                },
                child: const Text('Actualizar'),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _updateEmail(AuthManagementService authManagementService, UserProfileProvider userProfileProvider) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || userProfileProvider.currentUserModel?.userType == 'Google') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes cambiar el email para usuarios de Google.'),
          backgroundColor: AppTheme.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    bool reauthenticated = await _showReauthenticateDialog(authManagementService);
    if (!mounted) return;
    if (!reauthenticated) return;

    _newEmailController.clear();
    _confirmNewEmailController.clear();
    
    if(!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Actualizar Correo Electrónico'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Nuevo Correo Electrónico'),
            ),
            TextField(
              controller: _confirmNewEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Confirmar Nuevo Correo Electrónico'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (_newEmailController.text.isEmpty || !_newEmailController.text.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor, ingresa un correo electrónico válido.'),
                    backgroundColor: AppTheme.error,
                    duration: Duration(seconds: 3),
                  ),
                );
                return;
              }
              if (_newEmailController.text != _confirmNewEmailController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Los correos electrónicos no coinciden.'),
                    backgroundColor: AppTheme.error,
                    duration: Duration(seconds: 3),
                  ),
                );
                return;
              }

              try {
                await authManagementService.updateEmail(_newEmailController.text);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Se ha enviado un enlace de verificación a tu nuevo correo.'), backgroundColor: AppTheme.success, duration: Duration(seconds: 3)),
                );
                Navigator.of(context).pop();
              } on FirebaseAuthException catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Error al actualizar correo: ${e.message}'),
                  backgroundColor: AppTheme.error,
                  duration: Duration(seconds: 3),
                ));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Error desconocido al actualizar correo: $e'),
                  backgroundColor: AppTheme.error,
                  duration: Duration(seconds: 3),
                ));
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(AuthManagementService authManagementService) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay usuario autenticado.'),
          backgroundColor: AppTheme.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    bool reauthenticated = await _showReauthenticateDialog(authManagementService);
    if (!mounted) return;
    if (!reauthenticated) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cuenta'),
        content: const Text('¿Estás seguro de que quieres eliminar tu cuenta? Esta acción es irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar', style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await authManagementService.deleteAccount();
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta eliminada exitosamente.'), backgroundColor: AppTheme.success, duration: Duration(seconds: 3)),
      );
      
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al eliminar cuenta: ${e.message}'),
        backgroundColor: AppTheme.error,
        duration: Duration(seconds: 3),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error desconocido al eliminar cuenta: $e'),
        backgroundColor: AppTheme.error,
        duration: Duration(seconds: 3),
      ));
    }
  }

  Future<void> _updateBusinessInfo(UserProfileProvider userProfileProvider) async {
    _populateControllers(userProfileProvider.currentUserModel); 

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Actualizar Información del Negocio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _businessNameController, decoration: const InputDecoration(labelText: 'Nombre del Negocio')),
              const SizedBox(height: 16),
              TextField(controller: _businessAddressController, decoration: const InputDecoration(labelText: 'Dirección del Negocio')),
              const SizedBox(height: 16),
              TextField(controller: _paymentInstructionsController, maxLines: 3, decoration: const InputDecoration(labelText: 'Instrucciones de Pago')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await userProfileProvider.updateProfile(
                fullName: userProfileProvider.currentUserModel!.fullName, 
                businessName: _businessNameController.text.trim(),
                businessAddress: _businessAddressController.text.trim(),
                paymentInstructions: _paymentInstructionsController.text.trim(),
              );
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        cacheDir.deleteSync(recursive: true);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Caché eliminada exitosamente.'), backgroundColor: AppTheme.success, duration: Duration(seconds: 3)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar caché: $e'), backgroundColor: AppTheme.error, duration: Duration(seconds: 3)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener los providers necesarios
    final authService = Provider.of<AuthManagementService>(context, listen: false);
    final userProfileProvider = Provider.of<UserProfileProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración del Vendedor'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Sección de Cuenta
          _buildSectionHeader('Cuenta'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Cambiar Contraseña'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _updatePassword(authService, userProfileProvider),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Cambiar Correo Electrónico'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _updateEmail(authService, userProfileProvider),
          ),

          const SizedBox(height: 24),
          
          // Sección de Negocio
          _buildSectionHeader('Negocio'),
          ListTile(
            leading: const Icon(Icons.store_mall_directory_outlined),
            title: const Text('Información del Negocio'),
            subtitle: const Text('Editar nombre, dirección e instrucciones de pago'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _updateBusinessInfo(userProfileProvider),
          ),

          const SizedBox(height: 24),

          // Sección de Preferencias
          _buildSectionHeader('Preferencias'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Modo Oscuro'),
            // Ahora esto funcionará gracias a la corrección en ThemeProvider
            value: themeProvider.isDarkMode,
            onChanged: (bool value) {
              themeProvider.toggleTheme();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notificaciones'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationPreferencesScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacidad'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacySettingsScreen()),
              );
            },
          ),

          const SizedBox(height: 24),

          // Sección de Sistema y Peligro
          _buildSectionHeader('Sistema'),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Limpiar Caché'),
            onTap: _clearCache,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppTheme.error),
            title: const Text('Eliminar Cuenta', style: TextStyle(color: AppTheme.error)),
            onTap: () => _deleteAccount(authService),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}