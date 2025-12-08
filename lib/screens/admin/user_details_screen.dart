import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/user.dart';

class UserDetailsScreen extends StatelessWidget {
  final UserModel user;

  const UserDetailsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning),
            onPressed: () => _showSendNotificationDialog(context, user),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              maxWidth: 800), // Limit width for details content
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user.profilePicture != null)
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(user.profilePicture!),
                    ),
                  ),
                const SizedBox(height: 16.0),
                _buildDetailRow('Nombre Completo', user.fullName),
                _buildDetailRow('Email', user.email),
                _buildDetailRow('Tipo de Usuario', user.userType),
                if (user.dob != null)
                  _buildDetailRow('Fecha de Nacimiento', user.dob!),
                if (user.rfc != null) _buildDetailRow('RFC', user.rfc!),
                if (user.phoneNumber != null)
                  _buildDetailRow('Teléfono', user.phoneNumber!),
                if (user.placeOfBirth != null)
                  _buildDetailRow('Lugar de Nacimiento', user.placeOfBirth!),
                if (user.address != null)
                  _buildDetailRow('Dirección', user.address!),
                if (user.businessName != null)
                  _buildDetailRow('Nombre del Negocio', user.businessName!),
                if (user.businessAddress != null)
                  _buildDetailRow(
                      'Dirección del Negocio', user.businessAddress!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4.0),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
          const Divider(),
        ],
      ),
    );
  }

  void _showSendNotificationDialog(BuildContext context, UserModel user) {
    final notificationController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enviar Notificación a ${user.fullName}'),
          content: TextField(
            controller: notificationController,
            decoration: const InputDecoration(
              hintText: 'Escribe tu mensaje aquí...',
            ),
            maxLines: 5,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (notificationController.text.isNotEmpty) {
                  final notificationsRef =
                      FirebaseDatabase.instance.ref('notifications/${user.id}');
                  await notificationsRef.push().set({
                    'message': notificationController.text,
                    'timestamp': ServerValue.timestamp,
                  });
                  if (!context.mounted) return; // Added mounted check
                  Navigator.pop(context);
                  if (!context.mounted) return; // Added mounted check
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Notificación enviada con éxito.'),
                        backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }
}
