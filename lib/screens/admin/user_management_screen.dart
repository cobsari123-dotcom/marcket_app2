import 'package:flutter/material.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/providers/user_management_provider.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => UserManagementScreenState();
}

class UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  late UserManagementProvider _userManagementProvider;

  @override
  void initState() {
    super.initState();
    _userManagementProvider = Provider.of<UserManagementProvider>(context, listen: false);
    _userManagementProvider.init(); // Cargar usuarios al inicio
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _userManagementProvider.setSearchQuery(_searchController.text);
  }

  Future<void> _deleteUser(BuildContext context, UserModel user) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar a ${user.fullName}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar', style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _userManagementProvider.deleteUser(user);
        if (mounted) {
          if (_userManagementProvider.errorMessage == null) {
            final Uri emailLaunchUri = Uri(
              scheme: 'mailto',
              path: user.email,
              query: 'subject=Notificación de eliminación de cuenta&body=Hola ${user.fullName},\n\nTu cuenta en Manos del Mar ha sido eliminada por un administrador.\n\nSi crees que esto es un error, por favor, contacta a soporte.\n\nGracias,\nEl equipo de Manos del Mar',
            );
            await launchUrl(emailLaunchUri);
            if (!mounted) return; // Add this check
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('¡Usuario eliminado exitosamente!'), duration: Duration(seconds: 3), backgroundColor: AppTheme.success),
            );
          } else {
            if (!mounted) return; // Add this check
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al eliminar usuario: ${_userManagementProvider.errorMessage}'), duration: const Duration(seconds: 3), backgroundColor: AppTheme.error),
            );
          }
        }
      } catch (e) {
        if (!mounted) return; // Add this check
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ocurrió un error inesperado al eliminar el usuario: $e'), duration: const Duration(seconds: 3), backgroundColor: AppTheme.error),
        );
      } // Added this closing brace
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // Limit width for the user management content
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar usuarios...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(25.0)))
                  ),
                ),
              ),
              Expanded(
                child: Consumer<UserManagementProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (provider.errorMessage != null) {
                      return Center(child: Text('Error: ${provider.errorMessage}'));
                    }
                    if (provider.users.isEmpty) {
                      return const Center(child: Text('No hay usuarios registrados.'));
                    }

                    final filteredUsers = provider.users.where((user) {
                      final query = provider.searchQuery.toLowerCase();
                      return user.fullName.toLowerCase().contains(query) ||
                             user.email.toLowerCase().contains(query);
                    }).toList();

                    if (filteredUsers.isEmpty) {
                      return const Center(child: Text('No se encontraron usuarios que coincidan con la búsqueda.'));
                    }

                    return ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user.profilePicture != null ? NetworkImage(user.profilePicture!) : null,
                            child: user.profilePicture == null ? const Icon(Icons.person) : null,
                          ),
                          title: Text(user.fullName),
                          subtitle: Text(user.email),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: AppTheme.error),
                            onPressed: () => _deleteUser(context, user),
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/public_seller_profile',
                              arguments: {
                                'sellerId': user.id,
                                'isAdmin': true,
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
