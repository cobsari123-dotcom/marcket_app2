import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marcket_app/providers/product_list_provider.dart';
import 'package:marcket_app/screens/seller/my_products_screen.dart';
import 'package:marcket_app/screens/seller/seller_orders_screen.dart';
import 'package:marcket_app/screens/seller/seller_profile_screen.dart';

import 'package:marcket_app/screens/seller/seller_settings_screen.dart';
import 'package:marcket_app/screens/seller/seller_publications_screen.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/screens/chat/chat_list_screen.dart';
import 'package:marcket_app/screens/common/admin_alerts_screen.dart';
import 'package:marcket_app/screens/common/contact_support_screen.dart';
import 'package:marcket_app/screens/common/notifications_screen.dart';
import 'package:marcket_app/screens/common/about_us_screen.dart'; // Added import
import 'package:marcket_app/widgets/responsive_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:marcket_app/services/auth_management_service.dart';
import 'package:marcket_app/screens/common/welcome_dashboard_screen.dart'; // Added
// import 'package:marcket_app/screens/buyer/explore_products_screen.dart'; // Removed
// import 'package:marcket_app/screens/buyer/reels_publications_screen.dart'; // Removed


class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  int _selectedIndex = 0;
  UserModel? _currentUserModel;
  bool _isLoading = true; // Use _isLoading directly for header state

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot =
          await FirebaseDatabase.instance.ref('users/${user.uid}').get();
      if (snapshot.exists && mounted) {
        setState(() {
          _currentUserModel = UserModel.fromMap(
            Map<String, dynamic>.from(snapshot.value as Map),
            user.uid,
          );
          _isLoading = false; // Set loading to false once data is loaded
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
  }

  // Renamed from _onDrawerItemTapped for clarity and consistency
  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the Drawer
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = FirebaseAuth.instance.currentUser; // Get current Firebase user

    final List<Widget> widgetOptions = <Widget>[
      const Scaffold(body: WelcomeDashboardScreen()), // 0: Welcome Dashboard for Seller
      // ignore: prefer_const_constructors
      Scaffold(
        body: const MyProductsScreen(), // 1: My Products
      ),
      // ignore: prefer_const_constructors
      Scaffold(
        body: const SellerPublicationsScreen(), // 2: My Publications
      ),
      // ignore: prefer_const_constructors
      Scaffold(
        body: const SellerOrdersScreen(), // 3: My Sales
      ),
      // ignore: prefer_const_constructors
      Scaffold(
        body: const ChatListScreen(), // 4: Messages
      ),
      Scaffold(
        body: SellerProfileScreen(onProfileUpdated: _loadUserData), // 5: My Profile
      ),
      const Scaffold(body: SellerSettingsScreen()), // 6: Seller Settings
      const Scaffold(body: NotificationsScreen()), // 7: Notifications
      const Scaffold(body: ContactSupportScreen()), // 8: Support
      const Scaffold(body: AdminAlertsScreen()), // 9: Admin Alerts
      const Scaffold(body: AboutUsScreen()), // 10: About Us
    ];

    final drawer = Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(user), // Pass Firebase user
          _buildDrawerItem(Icons.home, 'Inicio', 0),
          _buildDrawerItem(Icons.shopping_bag, 'Mis Productos', 1),
          _buildDrawerItem(Icons.article, 'Mis Publicaciones', 2),
          _buildDrawerItem(Icons.point_of_sale, 'Mis Ventas', 3),
          _buildDrawerItem(Icons.chat, 'Mensajes', 4),
          _buildDrawerItem(Icons.person, 'Mi Perfil', 5),
          const Divider(),
          _buildDrawerItem(Icons.settings, 'Configuración', 6),
          _buildDrawerItem(Icons.notifications, 'Notificaciones', 7),
          _buildDrawerItem(Icons.support_agent, 'Soporte Técnico', 8),
          _buildDrawerItem(Icons.warning_amber_rounded, 'Alertas de Administrador', 9),
          _buildDrawerItem(Icons.info_outline, 'Sobre Nosotros', 10),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.error),
            title: Text(
              'Cerrar Sesión',
              style: textTheme.bodyMedium?.copyWith(color: AppTheme.error),
            ),
            onTap: () async {
              final authManagementService =
                  Provider.of<AuthManagementService>(context, listen: false);
              Navigator.pop(context);
              final bool? confirmLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmar Cierre de Sesión'),
                  content: const Text(
                      '¿Estás seguro de que quieres cerrar tu sesión?'),
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

              if (confirmLogout == true && mounted) {
                await authManagementService.signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Sesión cerrada correctamente.'),
                    duration: const Duration(seconds: 3),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                );
                await Future.delayed(const Duration(milliseconds: 500));
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );

    Widget? fab;
    if (_selectedIndex == 1) {
      // FAB for MyProductsScreen (Add Product)
      fab = FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_edit_product').then((_) {
            // Refresh the product list after adding/editing a product
            Provider.of<ProductListProvider>(context, listen: false)
                .refreshProducts();
          });
        },
        backgroundColor: AppTheme.secondary,
        child: const Icon(Icons.add, color: AppTheme.onSecondary),
      );
    } else if (_selectedIndex == 2) {
      // FAB for SellerPublicationsScreen (Add Publication)
      fab = FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create_edit_publication');
        },
        backgroundColor: AppTheme.secondary,
        child: const Icon(Icons.add, color: AppTheme.onSecondary),
      );
    }

    final List<String> appBarTitles = [
      'Bienvenida Vendedor', // 0
      'Mis Productos', // 1
      'Mis Publicaciones', // 2
      'Mis Ventas', // 3
      'Mensajes', // 4
      'Mi Perfil', // 5
      'Configuración', // 6
      'Notificaciones', // 7
      'Soporte Técnico', // 8
      'Alertas de Administrador', // 9
      'Sobre Nosotros', // 10
    ];

    return ResponsiveScaffold(
      pages: widgetOptions,
      drawer: drawer,
      initialIndex: _selectedIndex,
      onIndexChanged: _onItemTapped,
      floatingActionButton: fab,
      appBarTitle: Text(appBarTitles[_selectedIndex]),
    );
  }

  Widget _buildDrawerHeader(User? firebaseUser) {
    if (_isLoading) {
      return const DrawerHeader(
        decoration: BoxDecoration(color: AppTheme.primary),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return UserAccountsDrawerHeader(
      accountName: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentUserModel?.fullName ??
                firebaseUser?.displayName ??
                'Vendedor',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _getTranslatedRole(_currentUserModel?.userType),
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
      accountEmail: Text(
        firebaseUser?.email ?? 'vendedor@example.com',
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

  String _getTranslatedRole(String? userType) {
    switch (userType) {
      case 'Buyer':
        return 'Comprador';
      case 'Seller':
        return 'Vendedor';
      case 'Admin':
        return 'Administrador';
      default:
        return 'Rol Desconocido';
    }
  }

  // Ensure index is correctly handled in _buildDrawerItem
  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? AppTheme.primary
            : AppTheme.onBackground.withAlpha(180),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppTheme.primary : AppTheme.onBackground,
            ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.primary.withAlpha(25),
      onTap: () {
        _selectPage(index); // Use _selectPage to handle navigation and closing drawer
      },
    )
        .animate()
        .fade(duration: 300.ms, delay: (50 * index).ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms, delay: (50 * index).ms);
  }
} // Add this closing brace
