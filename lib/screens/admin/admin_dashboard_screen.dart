import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/chat_room.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/providers/admin_dashboard_provider.dart';
import 'package:marcket_app/providers/theme_provider.dart';
import 'package:marcket_app/screens/admin/admin_profile_screen.dart';
import 'package:marcket_app/screens/admin/admin_settings_screen.dart';
import 'package:marcket_app/screens/admin/admin_complaints_suggestions_screen.dart';
import 'package:marcket_app/screens/admin/user_management_screen.dart';
import 'package:marcket_app/screens/buyer/feed_screen.dart';
import 'package:marcket_app/services/auth_management_service.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:marcket_app/widgets/responsive_scaffold.dart';
import 'package:marcket_app/screens/common/about_us_screen.dart'; // Added import
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => AdminDashboardScreenState();
}

class AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const List<String> _titles = <String>[
    'Soporte Técnico',
    'Quejas y Sugerencias',
    'Mi Perfil',
    'Gestión de Usuarios',
    'Feed de Publicaciones',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer2<AdminDashboardProvider, ThemeProvider>(
      builder: (context, adminProvider, themeProvider, child) {
        final List<Widget> adminScreens = [
          const SupportChatList(),
          const AdminComplaintsSuggestionsScreen(),
          const AdminProfileScreen(),
          const UserManagementScreen(),
          const FeedScreen(isAdmin: true),
        ];

        final List<NavigationRailDestination> destinations = [
          const NavigationRailDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent),
            label: Text('Soporte'),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.feedback_outlined),
            selectedIcon: Icon(Icons.feedback),
            label: Text('Quejas'),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: Text('Perfil'),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: Text('Usuarios'),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.dynamic_feed_outlined),
            selectedIcon: Icon(Icons.dynamic_feed),
            label: Text('Feed'),
          ),
        ];

        final drawer = Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              _buildDrawerHeader(
                adminProvider.currentUserModel,
                adminProvider.isLoadingUserData,
              ),
              _buildDrawerItem(
                Icons.support_agent,
                'Soporte Técnico',
                0,
                adminProvider,
              ),
              _buildDrawerItem(
                Icons.feedback,
                'Quejas y Sugerencias',
                1,
                adminProvider,
              ),
              _buildDrawerItem(Icons.person, 'Mi Perfil', 2, adminProvider),
              const Divider(),
              _buildDrawerItem(
                Icons.people,
                'Gestión de Usuarios',
                3,
                adminProvider,
              ),
              _buildDrawerItem(
                Icons.dynamic_feed,
                'Feed de Publicaciones',
                4,
                adminProvider,
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configuración'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const AdminSettingsScreen()));
                                },              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Sobre Nosotros'),
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
                title: const Text('Cerrar Sesión'),
                onTap: () async {
                  Navigator.pop(context);
                  final bool? confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Cerrar Sesión'),
                      content: const Text(
                          '¿Estás seguro de que quieres cerrar sesión?'),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text(
                            'Sí, Cerrar Sesión',
                            style: TextStyle(color: AppTheme.error),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && mounted) {
                    final authManagementService =
                        Provider.of<AuthManagementService>(context,
                            listen: false);
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
                        context, '/', (route) => false);
                  }
                },
              ),
            ],
          ),
        );

        return ResponsiveScaffold(
          pages: adminScreens,
          titles: _titles,
          destinations: destinations,
          drawer: drawer,
          initialIndex: adminProvider.selectedIndex,
          onIndexChanged: (index) {
            adminProvider.setSelectedIndex(index);
          },
        );
      },
    );
  }

  Widget _buildDrawerHeader(UserModel? currentUserModel, bool isLoading) {
    if (isLoading) {
      return const DrawerHeader(
        decoration: BoxDecoration(color: AppTheme.primary),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return UserAccountsDrawerHeader(
      accountName: Text(
        currentUserModel?.fullName ?? 'Administrador',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      accountEmail: Text(
        currentUserModel?.email ?? 'admin@example.com',
        style: const TextStyle(color: Colors.white70),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: AppTheme.secondary,
        backgroundImage: currentUserModel?.profilePicture != null
            ? NetworkImage(currentUserModel!.profilePicture!)
            : null,
        child: currentUserModel?.profilePicture == null
            ? const Icon(
                Icons.person_pin,
                size: 40,
                color: AppTheme.onSecondary,
              )
            : null,
      ),
      decoration: const BoxDecoration(color: AppTheme.primary),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    int index,
    AdminDashboardProvider adminProvider,
  ) {
    final isSelected = adminProvider.selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? AppTheme.primary
            : AppTheme.onBackground.withAlpha(180),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.primary : AppTheme.onBackground,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.primary.withAlpha(25),
      onTap: () {
        adminProvider.setSelectedIndex(index);
        Navigator.pop(context); // Cerrar el Drawer
      },
    )
        .animate()
        .fade(duration: 300.ms, delay: (50 * index).ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms, delay: (50 * index).ms);
  }
}

class SupportChatList extends StatefulWidget {
  const SupportChatList({super.key});

  @override
  State<SupportChatList> createState() => SupportChatListState();
}

class SupportChatListState extends State<SupportChatList> {
  final Map<String, Map<String, String>> _usersData = {};
  bool _isLoading = true;

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate.isAtSameMomentAs(today)) {
      return DateFormat('HH:mm').format(timestamp);
    } else {
      return DateFormat('dd/MM HH:mm').format(timestamp);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUsersData();
  }

  Future<void> _fetchUsersData() async {
    try {
      final userSnapshot = await FirebaseDatabase.instance.ref('users').get();
      if (userSnapshot.exists) {
        final usersData = Map<String, dynamic>.from(userSnapshot.value as Map);
        final Map<String, Map<String, String>> names = {};
        usersData.forEach((key, value) {
          final userData = Map<String, dynamic>.from(value as Map);
          names[key] = {
            'fullName': userData['fullName'] ?? 'Usuario Desconocido',
            'userType': userData['userType'] ?? 'N/A',
          };
        });
        if (mounted) {
          setState(() {
            _usersData.addAll(names);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching user names: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final DatabaseReference chatRoomsRef = FirebaseDatabase.instance.ref(
      'chat_rooms',
    );

    return StreamBuilder(
      stream: chatRoomsRef
          .orderByKey()
          .startAt('support_')
          .endAt('support_\uf8ff')
          .onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const Center(child: Text('No hay conversaciones de soporte.'));
        }

        final chatRoomsMap = Map<String, dynamic>.from(
          snapshot.data!.snapshot.value as Map,
        );
        final chatRooms = chatRoomsMap.entries.map((entry) {
          return ChatRoom.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
            entry.key,
          );
        }).toList();

        chatRooms.sort(
          (a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp),
        );

        return ListView.builder(
          itemCount: chatRooms.length,
          itemBuilder: (context, index) {
            final room = chatRooms[index];
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
            final otherParticipantId = room.participants.keys.firstWhere(
              (p) => p != currentUserId,
              orElse: () => room.participants.keys.first, // Fallback
            );
            final userName =
                _usersData[otherParticipantId]?['fullName'] ?? 'Cargando...';
            final userType = _usersData[otherParticipantId]?['userType'] ?? '';

            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.secondary,
                child: Icon(Icons.person, color: AppTheme.onSecondary),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(userType),
                    labelStyle: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white),
                    backgroundColor: userType.toLowerCase() == 'seller'
                        ? AppTheme.primary
                        : userType.toLowerCase() == 'buyer'
                            ? AppTheme.secondary
                            : Colors.grey,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4.0, vertical: 0),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              subtitle: Text(
                room.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                _formatTimestamp(
                  room.lastMessageTimestamp,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onTap: () {
                if (!mounted) return;
                Navigator.pushNamed(
                  context,
                  '/chat',
                  arguments: {'chatRoomId': room.id, 'otherUserName': userName},
                );
              },
            );
          },
        );
      },
    );
  }
}
