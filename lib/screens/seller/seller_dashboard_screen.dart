import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marcket_app/providers/product_list_provider.dart';
import 'package:marcket_app/screens/buyer/feed_screen.dart';
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
    'Mis Publicaciones',
    'Mis Ventas',
    'Mensajes',
    'Mi Perfil',
  ];

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
  }

  void _onDrawerItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final List<Widget> widgetOptions = <Widget>[
      const FeedScreen(isAdmin: false),
      const MyProductsScreen(),
      const SellerPublicationsScreen(),
      const SellerOrdersScreen(),
      const ChatListScreen(),
      SellerProfileScreen(onProfileUpdated: _loadUserData),
    ];

    final List<NavigationRailDestination> destinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: Text('Inicio'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.shopping_bag_outlined),
        selectedIcon: Icon(Icons.shopping_bag),
        label: Text('Productos'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.article_outlined),
        selectedIcon: Icon(Icons.article),
        label: Text('Publicaciones'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.point_of_sale_outlined),
        selectedIcon: Icon(Icons.point_of_sale),
        label: Text('Ventas'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.chat_outlined),
        selectedIcon: Icon(Icons.chat),
        label: Text('Mensajes'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.person_outlined),
        selectedIcon: Icon(Icons.person),
        label: Text('Perfil'),
      ),
    ];

    final drawer = Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(),
          _buildDrawerItem(Icons.home, 'Inicio', 0),
          _buildDrawerItem(Icons.shopping_bag, 'Mis Productos', 1),
          _buildDrawerItem(Icons.article, 'Mis Publicaciones', 2),
          _buildDrawerItem(Icons.point_of_sale, 'Mis Ventas', 3),
          _buildDrawerItem(Icons.chat, 'Mensajes', 4),
          _buildDrawerItem(Icons.person, 'Mi Perfil', 5),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SellerSettingsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notificaciones'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Soporte Técnico'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ContactSupportScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded),
            title: const Text('Alertas de Administrador'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdminAlertsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.info_outline,
              color: AppTheme.secondary,
            ),
            title: const Text('Sobre Nosotros'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutUsScreen(),
                ),
              );
            },
          ),
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
      // FAB for MyProductsScreen
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
      // FAB for SellerPublicationsScreen (new)
      fab = FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create_edit_publication');
        },
        backgroundColor: AppTheme.secondary,
        child: const Icon(Icons.add, color: AppTheme.onSecondary),
      );
    }

    return ResponsiveScaffold(
      pages: widgetOptions,
      titles: _titles,
      destinations: destinations,
      drawer: drawer,
      initialIndex: _selectedIndex,
      onIndexChanged: _onItemTapped,
      floatingActionButton: fab,
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
        _onDrawerItemTapped(index);
      },
    )
        .animate()
        .fade(duration: 300.ms, delay: (50 * index).ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms, delay: (50 * index).ms);
  }
}
