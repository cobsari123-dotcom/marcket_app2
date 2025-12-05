import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/providers/theme_provider.dart';
import 'package:marcket_app/providers/user_profile_provider.dart';
import 'package:marcket_app/services/auth_management_service.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:path_provider/path_provider.dart'; // Import path_provider
import 'dart:io'; // Import for Directory
import 'package:image_picker/image_picker.dart'; // For profile picture update
import 'package:firebase_storage/firebase_storage.dart'; // For profile picture upload
import 'package:provider/provider.dart';

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
                  duration: const Duration(seconds: 3),
                ));
                if (!mounted) return;
                Navigator.of(context).pop(false);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Error desconocido de reautenticación: $e'),
                  backgroundColor: AppTheme.error,
                  duration: const Duration(seconds: 3),
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
        SnackBar(
          content: const Text('No puedes cambiar la contraseña para usuarios de Google.'),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    bool reauthenticated = await _showReauthenticateDialog(authManagementService);
    if (!mounted) return;
    if (!reauthenticated) return;

    _newPasswordController.clear();
    _confirmNewPasswordController.clear();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                    setState(() => _obscureNewPassword = !_obscureNewPassword);
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
                    setState(() => _obscureConfirmNewPassword = !_obscureConfirmNewPassword);
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
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('La contraseña debe tener al menos 6 caracteres.'),
                    backgroundColor: AppTheme.error,
                    duration: const Duration(seconds: 3),
                  ),
                );
                return;
              }
              if (_newPasswordController.text != _confirmNewPasswordController.text) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Las contraseñas no coinciden.'),
                    backgroundColor: AppTheme.error,
                    duration: const Duration(seconds: 3),
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
                if (!mounted) return;
                Navigator.of(context).pop();
              } on FirebaseAuthException catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Error al actualizar contraseña: ${e.message}'),
                  backgroundColor: AppTheme.error,
                  duration: const Duration(seconds: 3),
                ));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Error desconocido al actualizar contraseña: $e'),
                  backgroundColor: AppTheme.error,
                  duration: const Duration(seconds: 3),
                ));
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateEmail(AuthManagementService authManagementService, UserProfileProvider userProfileProvider) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || userProfileProvider.currentUserModel?.userType == 'Google') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No puedes cambiar el email para usuarios de Google.'),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    bool reauthenticated = await _showReauthenticateDialog(authManagementService);
    if (!mounted) return;
    if (!reauthenticated) return;

    _newEmailController.clear();
    _confirmNewEmailController.clear();
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
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Por favor, ingresa un correo electrónico válido.'),
                    backgroundColor: AppTheme.error,
                    duration: const Duration(seconds: 3),
                  ),
                );
                return;
              }
              if (_newEmailController.text != _confirmNewEmailController.text) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Los correos electrónicos no coinciden.'),
                    backgroundColor: AppTheme.error,
                    duration: const Duration(seconds: 3),
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
                if (!mounted) return;
                Navigator.of(context).pop();
              } on FirebaseAuthException catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Error al actualizar correo: ${e.message}'),
                  backgroundColor: AppTheme.error,
                  duration: const Duration(seconds: 3),
                ));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Error desconocido al actualizar correo: $e'),
                  backgroundColor: AppTheme.error,
                  duration: const Duration(seconds: 3),
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
        SnackBar(
          content: const Text('No hay usuario autenticado.'),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 3),
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
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al eliminar cuenta: ${e.message}'),
        backgroundColor: AppTheme.error,
        duration: const Duration(seconds: 3),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error desconocido al eliminar cuenta: $e'),
        backgroundColor: AppTheme.error,
        duration: const Duration(seconds: 3),
      ));
    }
  }

    Future<void> _updateProfilePicture(UserProfileProvider userProfileProvider) async {

      final ImagePicker picker = ImagePicker();

      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

  

      if (image == null) return;

  

      userProfileProvider.setLoading(true);

      try {

        final String fileName = '${FirebaseAuth.instance.currentUser!.uid}_profile.jpg';

        final Reference storageRef = FirebaseStorage.instance.ref().child('profile_pictures').child(fileName);

        final UploadTask uploadTask = storageRef.putFile(File(image.path));

        final TaskSnapshot snapshot = await uploadTask;

        final String downloadUrl = await snapshot.ref.getDownloadURL();

  

        // Actualizar URL de la foto de perfil en Firebase Auth y Realtime Database

        await FirebaseAuth.instance.currentUser?.updatePhotoURL(downloadUrl);

        await userProfileProvider.updateProfile(

          fullName: userProfileProvider.currentUserModel!.fullName, // Mantener los demás datos

          profilePicture: downloadUrl,

        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('¡Foto de perfil actualizada!'), backgroundColor: AppTheme.success),

        );

      } catch (e) {

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text('Error al actualizar foto de perfil: $e'), backgroundColor: AppTheme.error),

        );

      } finally {

        userProfileProvider.setLoading(false);

      }

    }

  Future<void> _updateBusinessInfo(UserProfileProvider userProfileProvider) async {
    _populateControllers(userProfileProvider.currentUserModel); // Asegurar que los controladores tengan los valores actuales

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
                fullName: userProfileProvider.currentUserModel!.fullName, // Mantener los demás datos
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
    // La lógica de caché no usa Provider, se mantiene
    try {
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        cacheDir.deleteSync(recursive: true);
      }
      if (mounted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caché eliminada exitosamente.'), backgroundColor: AppTheme.success, duration: Duration(seconds: 3)),
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
    return Consumer2<UserProfileProvider, ThemeProvider>(
      builder: (context, userProfileProvider, themeProvider, child) {
        final userModel = userProfileProvider.currentUserModel;
        final currentUser = FirebaseAuth.instance.currentUser;

        if (userProfileProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (userProfileProvider.errorMessage != null) {
          return Center(child: Text('Error: ${userProfileProvider.errorMessage}'));
        }
        if (userModel == null || currentUser == null) {
          return const Center(child: Text('No hay datos de usuario.'));
        }

        _populateControllers(userModel); // Actualizar controladores con datos del provider

        final authManagementService = Provider.of<AuthManagementService>(context, listen: false);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800), // Limit width for settings content
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    margin: const EdgeInsets.only(bottom: 24.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Información General', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 20),
                          Center(
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundImage: userModel.profilePicture != null ? NetworkImage(userModel.profilePicture!) : null,
                                  child: userModel.profilePicture == null ? const Icon(Icons.store, size: 60, color: AppTheme.onSecondary) : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.camera_alt, color: AppTheme.primary),
                                    onPressed: () => _updateProfilePicture(userProfileProvider),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ListTile(leading: const Icon(Icons.email), title: const Text('Correo Electrónico'), subtitle: Text(currentUser.email ?? 'N/A')),
                          ListTile(leading: const Icon(Icons.person), title: const Text('Nombre Completo'), subtitle: Text(userModel.fullName)),
                          ListTile(leading: const Icon(Icons.badge), title: const Text('Tipo de Usuario'), subtitle: Text(userModel.userType)),
                          ListTile(leading: const Icon(Icons.phone), title: const Text('Número de Teléfono'), subtitle: Text(userModel.phoneNumber ?? 'N/A')),
                          ListTile(leading: const Icon(Icons.cake), title: const Text('Fecha de Nacimiento'), subtitle: Text(userModel.dob ?? 'N/A')),
                          ListTile(leading: const Icon(Icons.assignment_ind), title: const Text('RFC'), subtitle: Text(userModel.rfc ?? 'N/A')),
                          ListTile(leading: const Icon(Icons.location_city), title: const Text('Lugar de Nacimiento'), subtitle: Text(userModel.placeOfBirth ?? 'N/A')),
                          ListTile(leading: const Icon(Icons.home), title: const Text('Dirección Personal'), subtitle: Text(userModel.address ?? 'N/A')),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.only(bottom: 24.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Seguridad', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _updatePassword(authManagementService, userProfileProvider),
                            icon: const Icon(Icons.lock),
                            label: const Text('Actualizar Contraseña'),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), textStyle: Theme.of(context).textTheme.titleMedium),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _updateEmail(authManagementService, userProfileProvider),
                            icon: const Icon(Icons.mail),
                            label: const Text('Actualizar Correo Electrónico'),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), textStyle: Theme.of(context).textTheme.titleMedium),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _deleteAccount(authManagementService),
                            icon: const Icon(Icons.delete),
                            label: const Text('Eliminar Cuenta'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), textStyle: Theme.of(context).textTheme.titleMedium),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.only(bottom: 24.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Información del Negocio', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 20),
                          ListTile(
                            leading: const Icon(Icons.business_center),
                            title: const Text('Nombre del Negocio'),
                            subtitle: Text(userModel.businessName ?? 'N/A'),
                            trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _updateBusinessInfo(userProfileProvider)),
                          ),
                          ListTile(
                            leading: const Icon(Icons.location_on),
                            title: const Text('Dirección del Negocio'),
                            subtitle: Text(userModel.businessAddress ?? 'N/A'),
                            trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _updateBusinessInfo(userProfileProvider)),
                          ),
                          ListTile(
                            leading: const Icon(Icons.payment),
                            title: const Text('Instrucciones de Pago'),
                            subtitle: Text(userModel.paymentInstructions ?? 'N/A'),
                            trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _updateBusinessInfo(userProfileProvider)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.only(bottom: 24.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Preferencias', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 20),
                          SwitchListTile(
                            title: const Text('Modo Oscuro'),
                            value: userModel.isDarkModeEnabled ?? false,
                            onChanged: (bool value) async {
                              await userProfileProvider.updateProfile(
                                fullName: userModel.fullName, // Se requiere para el método updateProfile
                                isDarkModeEnabled: value,
                              );
                            },
                            secondary: const Icon(Icons.dark_mode),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.only(bottom: 24.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Utilidades', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _clearCache,
                            icon: const Icon(Icons.cleaning_services),
                            label: const Text('Eliminar Caché'),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), textStyle: Theme.of(context).textTheme.titleMedium),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}