import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/providers/feed_provider.dart';
import 'package:marcket_app/screens/buyer/buyer_orders_screen.dart';
import 'package:marcket_app/screens/buyer/buyer_profile_screen.dart';
import 'package:marcket_app/screens/buyer/buyer_settings_screen.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:marcket_app/screens/buyer/feed_screen.dart';
import 'package:marcket_app/screens/chat/chat_list_screen.dart';
import 'package:marcket_app/screens/common/admin_alerts_screen.dart';
import 'package:marcket_app/screens/common/contact_support_screen.dart';
import 'package:marcket_app/screens/common/notifications_screen.dart';
import 'package:marcket_app/screens/common/about_us_screen.dart'; // Added import
import 'package:marcket_app/screens/cart_screen.dart';
import 'package:marcket_app/screens/buyer/seller_search_screen.dart';
import 'package:marcket_app/services/cart_service.dart';
import 'package:marcket_app/screens/buyer/favorites_screen.dart';
import 'package:marcket_app/models/cart_item.dart';
import 'package:marcket_app/widgets/responsive_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  // Dependencies for the filter/sort dialog, moved from FeedScreen
  final List<String> _categories = [
    'Todas',
    'Artesanía',
    'Comida',
    'Servicios',
    'Otros'
  ];
  final Map<String, String> _sortByOptions = {
    'timestamp': 'Más Recientes',
    'title': 'Título',
  };

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
  }

  void _onDrawerItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer
  }

  void _showFilterSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Filtrar y Ordenar Publicaciones'),
          content: Consumer<FeedProvider>(
            builder: (context, provider, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Categoría:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: provider.selectedCategory ?? 'Todas',
                    onChanged: (String? newValue) {
                      provider
                          .setCategory(newValue == 'Todas' ? null : newValue);
                    },
                    items: _categories
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('Ordenar por:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: provider.sortBy,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        provider.setSortBy(newValue);
                      }
                    },
                    items: _sortByOptions.entries.map<DropdownMenuItem<String>>(
                        (MapEntry<String, String> entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text('Orden:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Switch(
                        value: provider.descending,
                        onChanged: (bool value) {
                          provider.setDescending(value);
                        },
                        activeThumbColor: AppTheme.primary,
                      ),
                      Text(provider.descending ? 'Descendente' : 'Ascendente'),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = FirebaseAuth.instance.currentUser;

    final List<Widget> buyerContent = [
      const FeedScreen(),
      const BuyerOrdersScreen(),
      BuyerProfileScreen(onProfileUpdated: _loadUserData),
      const ChatListScreen(),
      const FavoritesScreen(),
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
        label: Text('Pedidos'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.person_outlined),
        selectedIcon: Icon(Icons.person),
        label: Text('Perfil'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.chat_outlined),
        selectedIcon: Icon(Icons.chat),
        label: Text('Mensajes'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.favorite_border),
        selectedIcon: Icon(Icons.favorite),
        label: Text('Favoritos'),
      ),
    ];

    final drawer = Drawer(
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
              ),
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
          _buildDrawerItem(Icons.favorite, 'Favoritos', 4),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.settings,
              color: AppTheme.secondary,
            ),
            title: Text('Configuración', style: textTheme.bodyMedium),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const BuyerSettingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.notifications,
              color: AppTheme.secondary,
            ),
            title: Text('Notificaciones', style: textTheme.bodyMedium),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
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
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContactSupportScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.secondary,
            ),
            title:
                Text('Alertas de Administrador', style: textTheme.bodyMedium),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminAlertsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.info_outline,
              color: AppTheme.secondary,
            ),
            title: Text('Sobre Nosotros', style: textTheme.bodyMedium),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
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

              final bool? confirmed = await showDialog<bool>(
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

              if (confirmed == true && mounted) {
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
    if (_selectedIndex == 0) {
      // Only show FAB for FeedScreen
      fab = FloatingActionButton(
        onPressed: _showFilterSortDialog,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.filter_list),
      );
    }

    return ResponsiveScaffold(
      pages: buyerContent,
      titles: _titles,
      destinations: destinations,
      drawer: drawer,
      initialIndex: _selectedIndex,
      onIndexChanged: _onItemTapped,
      floatingActionButton: fab,
      appBarActions: _selectedIndex == 0
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
          : null,
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
      ),
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
      ),
      onTap: () {
        _onDrawerItemTapped(index);
      },
    )
        .animate()
        .fade(duration: 300.ms, delay: (50 * index).ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms, delay: (50 * index).ms);
  }
}
