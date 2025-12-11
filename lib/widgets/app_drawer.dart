import 'package:flutter/material.dart';
import 'package:marcket_app/models/user.dart';

class AppDrawer extends StatelessWidget {
  final UserModel user;
  final List<Widget> menuItems;

  const AppDrawer({
    super.key,
    required this.user,
    required this.menuItems,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user.fullName),
            accountEmail: Text(user.email),
            currentAccountPicture: CircleAvatar(
              backgroundImage: (user.profilePicture != null && user.profilePicture!.isNotEmpty)
                  ? NetworkImage(user.profilePicture!)
                  : null,
              child: (user.profilePicture == null || user.profilePicture!.isEmpty)
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
            otherAccountsPictures: [
              Chip(
                label: Text(
                  user.userType,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: _getRoleColor(user.userType),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: menuItems,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String userType) {
    switch (userType) {
      case 'admin':
        return Colors.red;
      case 'Seller':
        return Colors.green;
      case 'Buyer':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
