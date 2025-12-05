import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/screens/buyer/buyer_orders_screen.dart';
import 'package:marcket_app/screens/buyer/buyer_profile_screen.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:marcket_app/screens/buyer/feed_screen.dart';
import 'package:marcket_app/screens/chat/chat_list_screen.dart';
import 'package:marcket_app/screens/common/contact_support_screen.dart';
import 'package:marcket_app/screens/common/notifications_screen.dart';
import 'package:marcket_app/screens/cart_screen.dart';
import 'package:marcket_app/screens/buyer/seller_search_screen.dart';
import 'package:marcket_app/services/cart_service.dart';
import 'package:marcket_app/screens/buyer/favorites_screen.dart';
import 'package:marcket_app/models/cart_item.dart';
import 'package:provider/provider.dart';
import 'package:marcket_app/services/auth_management_service.dart';

class BuyerDashboardScreen extends StatefulWidget {
  const BuyerDashboardScreen({super.key});

  @override
  State<BuyerDashboardScreen> createState() => _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState extends State<BuyerDashboardScreen> {
  int _selectedIndex = 0;
  UserModel? _currentUserModel;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  final List<String> _titles = [
    'Inicio',
    'Mis Pedidos',
    'Mi Perfil',
    'Mensajes',
    'Favoritos',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await _databaseRef.child('users/${user.uid}').get();
      if (snapshot.exists && mounted) {
        setState(() {
          _currentUserModel = UserModel.fromMap(
            Map<String, dynamic>.from(snapshot.value as Map),
            user.uid,
          );
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (mounted) Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = FirebaseAuth.instance.currentUser;

    final List<Widget> buyerContent = [
      FeedScreen(),
      const BuyerOrdersScreen(),
      BuyerProfileScreen(onProfileUpdated: _loadUserData),
      const ChatListScreen(),
      const FavoritesScreen(), // Añadido
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        automaticallyImplyLeading: false,
        actions: _selectedIndex == 0
            ? [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SellerSearchScreen(),
                      ),
                    );
                  },
                ),
                StreamBuilder<List<CartItem>>(
                  stream: CartService().getCartStream(),
                  builder: (context, snapshot) {
                    int totalItems = 0;
                    if (snapshot.hasData) {
                      totalItems = snapshot.data!.fold<int>(
                        0,
                        (sum, item) => sum + item.quantity,
                      );
                    }
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_cart),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CartScreen(),
                              ),
                            );
                          },
                        ),
                        if (totalItems > 0)
                          Positioned(
                            right: 5,
                            top: 5,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$totalItems',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ]
            : null, // No actions for other tabs
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(
                _currentUserModel?.fullName ?? user?.displayName ?? 'Comprador',
                style: textTheme.titleLarge?.copyWith(
                  color: AppTheme.onPrimary,
                ),
              ),
              accountEmail: Text(
                user?.email ?? 'comprador@ejemplo.com',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onPrimary.withAlpha((255 * 0.8).round()),
                ), // Fixed deprecated
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppTheme.secondary,
                backgroundImage: _currentUserModel?.profilePicture != null
                    ? NetworkImage(_currentUserModel!.profilePicture!)
                    : null,
                child: _currentUserModel?.profilePicture == null
                    ? const Icon(
                        Icons.person,
                        size: 40,
                        color: AppTheme.onSecondary,
                      )
                    : null,
              ),
              decoration: const BoxDecoration(color: AppTheme.primary),
            ),
            _buildDrawerItem(Icons.home, 'Inicio', 0),
            _buildDrawerItem(Icons.shopping_bag, 'Mis Pedidos', 1),
            _buildDrawerItem(Icons.person, 'Mi Perfil', 2),
            _buildDrawerItem(Icons.chat, 'Mensajes', 3),
            _buildDrawerItem(Icons.favorite, 'Favoritos', 4), // Añadido
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.notifications,
                color: AppTheme.secondary,
              ),
              title: Text('Notificaciones', style: textTheme.bodyMedium),
              onTap: () {
                if (!mounted) return; // Added mounted check
                Navigator.pop(context); // Close drawer first
                if (!mounted) return; // Added mounted check
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.support_agent,
                color: AppTheme.secondary,
              ),
              title: Text('Soporte Técnico', style: textTheme.bodyMedium),
              onTap: () {
                if (!mounted) return; // Added mounted check
                Navigator.pop(context); // Close drawer first
                if (!mounted) return; // Added mounted check
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContactSupportScreen(),
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
                if (!mounted) return; // Guard for context in Provider.of
                final authManagementService =
                    Provider.of<AuthManagementService>(context, listen: false);
                if (!mounted) return; // Guard for context in Navigator.pop
                Navigator.pop(context); // Close the drawer first
                if (!mounted) return; // Guard for context in showDialog

                final bool? confirmed = await showDialog<bool>(
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

                if (confirmed == true) { // Removed '&& mounted' here as a mounted check is done before.
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
              },
            ),
          ],
        ),
      ),
      body: buyerContent[_selectedIndex],
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final textTheme = Theme.of(context).textTheme;
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? AppTheme.primary
            : AppTheme.onBackground.withAlpha((255 * 0.7).round()),
      ), // Fixed deprecated
      title: Text(
        title,
        style: textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.primary : AppTheme.onBackground,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.primary.withAlpha(
        (255 * 0.1).round(),
      ), // Fixed deprecated
      onTap: () {
        _onItemTapped(index);
      },
    );
  }
}
