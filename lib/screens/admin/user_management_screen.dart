import 'package:flutter/material.dart';
import 'package:marcket_app/providers/user_management_provider.dart';
import 'package:marcket_app/screens/admin/admin_user_detail_screen.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:provider/provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider =
        Provider.of<UserManagementProvider>(context, listen: false);
    provider.fetchUsers(); // Initial fetch

    _searchController.addListener(() {
      provider.filterUsers(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserManagementProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Buscar usuario por nombre o email',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: _buildUserList(provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserList(UserManagementProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(child: Text('Error: ${provider.errorMessage}'));
    }

    final users = provider.filteredUsers;

    if (users.isEmpty) {
      return const Center(child: Text('No se encontraron usuarios.'));
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.secondary,
              backgroundImage: user.profilePicture != null
                  ? NetworkImage(user.profilePicture!)
                  : null,
              child: user.profilePicture == null
                  ? const Icon(Icons.person, color: AppTheme.onSecondary)
                  : null,
            ),
            title: Text(user.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(user.email),
            trailing: Chip(
              label: Text(
                user.userType,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: user.userType == 'Seller'
                  ? AppTheme.primary
                  : AppTheme.secondary,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminUserDetailScreen(userId: user.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
