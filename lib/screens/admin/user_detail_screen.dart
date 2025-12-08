import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/providers/user_management_provider.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:provider/provider.dart';

class UserDetailScreen extends StatelessWidget {
  final UserModel user;

  const UserDetailScreen({super.key, required this.user});

  void _showSendAlertDialog(BuildContext context) {
    final alertController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enviar Alerta'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: alertController,
              decoration: const InputDecoration(
                labelText: 'Mensaje de Alerta',
                hintText: 'Describe la razón de la alerta...',
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El mensaje no puede estar vacío.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final adminId = FirebaseAuth.instance.currentUser?.uid;
                  if (adminId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Error: Administrador no autenticado.'),
                          backgroundColor: AppTheme.error),
                    );
                    return;
                  }

                  final newAlertRef =
                      FirebaseDatabase.instance.ref('alerts').push();
                  try {
                    await newAlertRef.set({
                      'userId': user.id,
                      'adminId': adminId,
                      'message': alertController.text.trim(),
                      'timestamp': DateTime.now().millisecondsSinceEpoch,
                      'status': 'sent', // 'sent', 'replied'
                    });

                    Navigator.of(context).pop(); // Close the dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Alerta enviada con éxito.'),
                          backgroundColor: AppTheme.success),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Error al enviar la alerta: $e'),
                          backgroundColor: AppTheme.error),
                    );
                  }
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user.fullName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 24),
            _buildInfoCard(context),
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: user.profilePicture != null
                ? NetworkImage(user.profilePicture!)
                : null,
            child: user.profilePicture == null
                ? const Icon(Icons.person, size: 60)
                : null,
          ),
          const SizedBox(height: 16),
          Text(user.fullName, style: Theme.of(context).textTheme.headlineSmall),
          Text(user.email, style: Theme.of(context).textTheme.bodyLarge),
          Chip(
            label: Text(user.userType,
                style: const TextStyle(color: Colors.white)),
            backgroundColor: user.userType == 'Seller'
                ? AppTheme.primary
                : AppTheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Información del Usuario',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildInfoRow('UID:', user.id),
            if (user.phoneNumber != null)
              _buildInfoRow('Teléfono:', user.phoneNumber!),
            if (user.dob != null)
              _buildInfoRow('Fecha de Nacimiento:', user.dob!),
            if (user.rfc != null) _buildInfoRow('RFC:', user.rfc!),
            if (user.placeOfBirth != null)
              _buildInfoRow('Lugar de Nacimiento:', user.placeOfBirth!),
            if (user.gender != null) _buildInfoRow('Sexo:', user.gender!),
            if (user.address != null)
              _buildInfoRow('Dirección:', user.address!),
            if (user.bio != null) _buildInfoRow('Biografía:', user.bio!),
            if (user.businessName != null) ...[
              const SizedBox(height: 16),
              const Text('Información del Negocio',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Divider(),
              _buildInfoRow('Nombre del Negocio:', user.businessName!),
              if (user.businessAddress != null)
                _buildInfoRow('Dirección del Negocio:', user.businessAddress!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _showSendAlertDialog(context),
          icon: const Icon(Icons.warning),
          label: const Text('Enviar Alerta'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirmar Eliminación'),
                content: Text(
                    '¿Estás seguro de que quieres eliminar la cuenta de ${user.fullName}? Esta acción no se puede deshacer.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Eliminar',
                        style: TextStyle(color: AppTheme.error)),
                  ),
                ],
              ),
            );

            if (confirmed == true && context.mounted) {
              final provider =
                  Provider.of<UserManagementProvider>(context, listen: false);
              await provider.deleteUser(user);

              if (context.mounted) {
                if (provider.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Error al eliminar: ${provider.errorMessage}'),
                        backgroundColor: AppTheme.error),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Usuario ${user.fullName} eliminado.'),
                        backgroundColor: AppTheme.success),
                  );
                  Navigator.of(context).pop();
                }
              }
            }
          },
          icon: const Icon(Icons.delete_forever),
          label: const Text('Eliminar Cuenta'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
        ),
      ],
    );
  }
}
