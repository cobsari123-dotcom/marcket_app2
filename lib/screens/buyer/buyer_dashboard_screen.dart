import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/user.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Importaciones de servicios y utilidades
import 'package:marcket_app/services/auth_management_service.dart';
import 'package:marcket_app/services/cart_service.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:marcket_app/models/cart_item.dart';
import 'package:marcket_app/widgets/responsive_scaffold.dart';

// Importaciones de Pantallas (Asegúrate de que estos archivos existan)
import 'package:marcket_app/screens/buyer/buyer_orders_screen.dart';
import 'package:marcket_app/screens/buyer/buyer_profile_screen.dart';
import 'package:marcket_app/screens/buyer/buyer_settings_screen.dart'; // Descomentado
import 'package:marcket_app/screens/chat/chat_list_screen.dart';
import 'package:marcket_app/screens/cart_screen.dart';
import 'package:marcket_app/screens/buyer/seller_search_screen.dart';
import 'package:marcket_app/screens/buyer/favorites_screen.dart';
import 'package:marcket_app/screens/common/welcome_dashboard_screen.dart';
import 'package:marcket_app/screens/buyer/explore_products_screen.dart';


// Importaciones de pantallas comunes (Descomentadas)
import 'package:marcket_app/screens/common/admin_alerts_screen.dart'; 
import 'package:marcket_app/screens/common/contact_support_screen.dart'; 
import 'package:marcket_app/screens/common/notifications_screen.dart'; 
import 'package:marcket_app/screens/common/about_us_screen.dart'; 

class BuyerDashboardScreen extends StatefulWidget {
  const BuyerDashboardScreen({super.key});

  @override
  State<BuyerDashboardScreen> createState() => _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState extends State<BuyerDashboardScreen> {
  int _selectedIndex = 0;
  UserModel? _currentUserModel;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Inicialización de las páginas
    // NOTA: He quitado 'const' de la mayoría para evitar errores de compilación
    // si las pantallas internas no son constantes.
    _pages = [
      const WelcomeDashboardScreen(), // 0
      const Scaffold(body: BuyerOrdersScreen()), // 1
      Scaffold(body: BuyerProfileScreen(onProfileUpdated: _loadUserData)), // 2
      const Scaffold(body: ChatListScreen()), // 3
      const Scaffold(body: FavoritesScreen()), // 4
      const Scaffold(body: ExploreProductsScreen()), // 5
      const Scaffold(body: BuyerSettingsScreen()), // 6
      const Scaffold(body: NotificationsScreen()), // 7
      const Scaffold(body: ContactSupportScreen()), // 8
      const Scaffold(body: AdminAlertsScreen()), // 9
      const Scaffold(body: AboutUsScreen()), // 10
    ];
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await _databaseRef.child('users/${user.uid}').get();
      if (snapshot.exists && snapshot.value is Map && mounted) {
        setState(() {
          final Map<dynamic, dynamic> rawData = snapshot.value as Map<dynamic, dynamic>;
          _currentUserModel = UserModel.fromMap(
            Map<String, dynamic>.from(rawData),
            user.uid,
          );
        });
      }
    }
  }

  void _onItemTapped(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = FirebaseAuth.instance.currentUser;

    final drawer = Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUserModel?.fullName ??
                      user?.displayName ??
                      'Comprador',
                  style: textTheme.titleLarge?.copyWith(
                    color: AppTheme.onPrimary,
                  ),
                ),
                Text(
                  _getTranslatedRole(_currentUserModel?.userType),
                  style: textTheme.titleSmall?.copyWith(
                    color: AppTheme.onPrimary.withAlpha((255 * 0.8).round()),
                  ),
                ),
              ],
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
          _buildDrawerItem(Icons.store, 'Explorar Productos', 5),
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
                if (mounted) {
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
              }
            },
          ),
        ],
      ),
    );

    Widget? fab; 

    final List<String> appBarTitles = [
      'Bienvenida', // 0
      'Mis Pedidos', // 1
      'Mi Perfil', // 2
      'Mensajes', // 3
      'Favoritos', // 4
      'Explorar Productos', // 5
      'Configuración', // 6
      'Notificaciones', // 7
      'Soporte Técnico', // 8
      'Alertas de Administrador', // 9
      'Sobre Nosotros', // 10
    ];

    List<Widget>? currentAppBarActions;
    if (_selectedIndex == 0) {
      currentAppBarActions = [
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
      ];
    }

    return ResponsiveScaffold(
      pages: _pages,
      drawer: drawer,
      initialIndex: _selectedIndex,
      onIndexChanged: _onItemTapped,
      floatingActionButton: fab,
      appBarTitle: Text(appBarTitles[_selectedIndex]),
      appBarActions: currentAppBarActions,
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
        _onItemTapped(index);
        Navigator.pop(context);
      },
    )
        .animate()
        .fade(duration: 300.ms, delay: (50 * index).ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms, delay: (50 * index).ms);
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
}