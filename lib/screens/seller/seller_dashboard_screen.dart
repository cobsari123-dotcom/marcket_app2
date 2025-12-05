import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marcket_app/screens/seller/home_screen.dart';
import 'package:marcket_app/screens/seller/my_products_screen.dart';
import 'package:marcket_app/screens/seller/seller_orders_screen.dart';
import 'package:marcket_app/screens/seller/seller_profile_screen.dart';
import 'package:marcket_app/screens/seller/seller_settings_screen.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/screens/chat/chat_list_screen.dart';
import 'package:marcket_app/screens/common/contact_support_screen.dart';
import 'package:marcket_app/screens/common/notifications_screen.dart';
import 'package:provider/provider.dart';
import 'package:marcket_app/services/auth_management_service.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  int _selectedIndex = 0;
  UserModel? _currentUserModel;
  bool _isLoading = true;

  static const List<String> _titles = <String>[
    'Inicio',
    'Mis Productos',
    'Mis Ventas',
    'Mensajes',
    'Mi Perfil',
    'Configuración',
    'Notificaciones',
    'Soporte Técnico',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseDatabase.instance
          .ref('users/${user.uid}')
          .get();
      if (snapshot.exists && mounted) {
        setState(() {
          _currentUserModel = UserModel.fromMap(
            Map<String, dynamic>.from(snapshot.value as Map),
            user.uid,
          );
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final List<Widget> widgetOptions = <Widget>[
      const SellerHomeScreen(),
      const MyProductsScreen(),
      const SellerOrdersScreen(),
      const ChatListScreen(),
      SellerProfileScreen(onProfileUpdated: _loadUserData), // Pass callback
      const SellerSettingsScreen(),
      const NotificationsScreen(), // Added
      const ContactSupportScreen(), // Added
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),

      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(),
            _buildDrawerItem(Icons.home, 'Inicio', 0),
            _buildDrawerItem(Icons.shopping_bag, 'Mis Productos', 1),
            _buildDrawerItem(Icons.point_of_sale, 'Mis Ventas', 2),
            _buildDrawerItem(Icons.chat, 'Mensajes', 3),
            _buildDrawerItem(Icons.person, 'Perfil', 4),
            _buildDrawerItem(Icons.settings, 'Configuración', 5),
            const Divider(),
            _buildDrawerItem(Icons.notifications, 'Notificaciones', 6), // New index
            _buildDrawerItem(Icons.support_agent, 'Soporte Técnico', 7), // New index
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.error),
              title: Text(
                'Cerrar Sesión',
                style: textTheme.bodyMedium?.copyWith(color: AppTheme.error),
              ),
                            onTap: () async {
                              if (!mounted) return; // Guard for context in Provider.of
                              final authManagementService = Provider.of<AuthManagementService>(context, listen: false);
                              if (!mounted) return; // Guard for context in Navigator.pop
                              Navigator.pop(context); // Close the drawer first
                              if (!mounted) return; // Guard for context in showDialog
                              final bool? confirmLogout = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirmar Cierre de Sesión'),
                                  content: const Text('¿Estás seguro de que quieres cerrar tu sesión?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('Cerrar Sesión'),
                                    ),
                                  ],
                                ),
                              );
              
                              if (confirmLogout == true) { // Removed '&& mounted' here as a mounted check is done before.
                                await authManagementService.signOut();
                                if (!mounted) return; // Guard for context in ScaffoldMessenger
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Sesión cerrada correctamente.'),
                                    duration: const Duration(seconds: 3),
                                    backgroundColor: Theme.of(context).primaryColor,
                                  ),
                                );
                                // Allow time for SnackBar to show before navigating
                                await Future.delayed(const Duration(milliseconds: 500));
                                if (!mounted) return; // Guard for context in Navigator.pushNamedAndRemoveUntil
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/',
                                  (route) => false,
                                );
                              }
                            },            ),
          ],
        ),
      ),
      body: widgetOptions.elementAt(_selectedIndex),
    );
  }

  Widget _buildDrawerHeader() {
    if (_isLoading) {
      return const DrawerHeader(
        decoration: BoxDecoration(color: AppTheme.primary),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return UserAccountsDrawerHeader(
      accountName: Text(
        _currentUserModel?.fullName ?? 'Vendedor',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      accountEmail: Text(
        _currentUserModel?.email ?? 'vendedor@example.com',
        style: const TextStyle(color: Colors.white70),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: AppTheme.secondary,
        backgroundImage: _currentUserModel?.profilePicture != null
            ? NetworkImage(_currentUserModel!.profilePicture!)
            : null,
        child: _currentUserModel?.profilePicture == null
            ? const Icon(Icons.store, size: 40, color: AppTheme.onSecondary)
            : null,
      ),
      decoration: const BoxDecoration(color: AppTheme.primary),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      // CORREGIDO: .withOpacity() -> .withValues(alpha: )
      leading: Icon(
        icon,
        color: isSelected
            ? AppTheme.primary
            : AppTheme.onBackground.withValues(alpha: 0.7),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.primary : AppTheme.onBackground,
        ),
      ),
      selected: isSelected,
      // CORREGIDO: .withOpacity() -> .withValues(alpha: )
      selectedTileColor: AppTheme.primary.withValues(alpha: 0.1),
      onTap: () {
        _onItemTapped(index);
      },
    );
  }
}
