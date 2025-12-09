import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/user.dart' as app_user;
import 'package:marcket_app/models/product.dart';
import 'package:marcket_app/models/publication.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:marcket_app/widgets/product_card.dart';
import 'package:marcket_app/widgets/publication_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:marcket_app/screens/seller/product_details_screen.dart';
import 'package:marcket_app/services/sanction_service.dart';
import 'package:marcket_app/models/sanction.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marcket_app/services/user_service.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final String userId;

  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen>
    with SingleTickerProviderStateMixin {
  app_user.UserModel? _user;
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;
  final SanctionService _sanctionService = SanctionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final snapshot =
          await FirebaseDatabase.instance.ref('users/${widget.userId}').get();
      if (snapshot.exists && mounted) {
        setState(() {
          _user = app_user.UserModel.fromMap(
              Map<String, dynamic>.from(snapshot.value as Map), snapshot.key!);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Usuario no encontrado.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar los datos del usuario: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user?.fullName ?? 'Detalle de Usuario'),
        bottom: _user?.userType == 'Seller'
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.person), text: 'Perfil'),
                  Tab(icon: Icon(Icons.shopping_bag), text: 'Productos'),
                  Tab(icon: Icon(Icons.article), text: 'Publicaciones'),
                ],
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withAlpha(178),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _user == null
                  ? const Center(
                      child: Text('Datos de usuario no disponibles.'))
                  : _user!.userType == 'Seller'
                      ? TabBarView(
                          controller: _tabController,
                          children: [
                            _buildProfileTab(_user!),
                            _AdminProductsList(sellerId: _user!.id),
                            _AdminPublicationsList(sellerId: _user!.id),
                          ],
                        )
                      : _buildProfileTab(_user!),
    );
  }

  Future<void> _confirmAndDeleteUser(
      BuildContext context, app_user.UserModel user) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Eliminación de Cuenta'),
        content: Text(
            '¿Estás seguro de que quieres eliminar la cuenta de ${user.fullName} (${user.email})? Esta acción es irreversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Send deletion sanction first
        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin no autenticado.')),
          );
          return;
        }

        final sanction = Sanction(
          id: '', // Will be generated by Firebase
          userId: user.id,
          adminId: currentUser.uid,
          type: SanctionType.deletion,
          message:
              'Tu cuenta ha sido eliminada permanentemente debido a una violación de nuestras políticas. Si crees que esto es un error, por favor, contacta a soporte.',
          timestamp: DateTime.now(),
          reason: 'Violación de políticas', // Default reason for deletion
          duration: SanctionDuration.permanent,
          status: SanctionStatus.resolved, // Deletion is a final resolution
        );
        await _sanctionService.sendSanction(sanction);

        // Then delete the user
        await _userService.deleteUser(user.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Cuenta de ${user.fullName} eliminada exitosamente.')),
          );
          Navigator.of(context).pop(); // Go back to user management screen
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar la cuenta: $e')),
          );
        }
      }
    }
  }

  Future<void> _showSuspendUserDialog(
      BuildContext context, app_user.UserModel user) async {
    final TextEditingController reasonController = TextEditingController();
    SanctionDuration selectedDuration = SanctionDuration.oneWeek;
    DateTime? customEndDate;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Suspender Cuenta de Usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Suspendiendo a: ${user.fullName} (${user.email})'),
                const SizedBox(height: 16),
                DropdownButtonFormField<SanctionDuration>(
                  initialValue: selectedDuration,
                  decoration: const InputDecoration(
                    labelText: 'Duración de la Suspensión',
                    border: OutlineInputBorder(),
                  ),
                  items: SanctionDuration.values
                      .map((duration) => DropdownMenuItem(
                            value: duration,
                            child: Text(duration.toString().split('.').last),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedDuration = value;
                        if (selectedDuration != SanctionDuration.custom) {
                          customEndDate = null;
                        }
                      });
                    }
                  },
                ),
                if (selectedDuration == SanctionDuration.custom) ...[
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(customEndDate == null
                        ? 'Seleccionar Fecha de Fin'
                        : 'Fecha de Fin: ${customEndDate!.toLocal().toString().split(' ')[0]}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null && picked != customEndDate) {
                        setState(() {
                          customEndDate = picked;
                        });
                      }
                    },
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Razón de la suspensión (requerido)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reasonController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('La razón es requerida.')),
                  );
                  return;
                }
                if (selectedDuration == SanctionDuration.custom && customEndDate == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Selecciona una fecha de fin para la suspensión personalizada.')),
                  );
                  return;
                }

                final currentUser = _auth.currentUser;
                if (currentUser == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Admin no autenticado.')),
                  );
                  return;
                }

                DateTime calculatedEndDate;
                if (selectedDuration == SanctionDuration.oneWeek) {
                  calculatedEndDate = DateTime.now().add(const Duration(days: 7));
                } else if (selectedDuration == SanctionDuration.oneMonth) {
                  calculatedEndDate = DateTime.now().add(const Duration(days: 30)); // Approximation
                } else if (selectedDuration == SanctionDuration.permanent) {
                  calculatedEndDate = DateTime.utc(2100, 1, 1); // Effectively permanent
                } else { // Custom duration
                  calculatedEndDate = customEndDate!;
                }

                try {
                  // Update user's suspension status
                  await _userService.updateUserData(user.id, {
                    'isSuspended': true,
                    'suspensionEndDate': calculatedEndDate.toIso8601String(),
                  });

                  // Update local state immediately
                  _user = _user!.copyWith(
                    isSuspended: true,
                    suspensionEndDate: calculatedEndDate.toIso8601String(),
                  );


                  // Send suspension sanction
                  final sanction = Sanction(
                    id: '', // Generated by Firebase
                    userId: user.id,
                    adminId: currentUser.uid,
                    type: SanctionType.suspension,
                    message:
                        'Tu cuenta ha sido suspendida hasta el ${calculatedEndDate.toLocal().toString().split(' ')[0]}. Razón: ${reasonController.text}. Si crees que esto es un error, por favor, contacta a soporte.',
                    timestamp: DateTime.now(),
                    reason: reasonController.text,
                    duration: selectedDuration,
                    status: SanctionStatus.active,
                  );
                  await _sanctionService.sendSanction(sanction);

                  if (mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Cuenta de ${user.fullName} suspendida exitosamente.')),
                    );
                    Navigator.of(dialogContext).pop();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                          content:
                              Text('Error al suspender la cuenta: $e')),
                    );
                  }
                }
              },
              child: const Text('Suspender'),
            ),
          ],
        );
      },
    );
  }

  // --- Previous methods ---
  Future<void> _unsuspendUser(
      BuildContext context, app_user.UserModel user) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Reactivación de Cuenta'),
        content: Text(
            '¿Estás seguro de que quieres reactivar la cuenta de ${user.fullName} (${user.email})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _userService.updateUserData(user.id, {
          'isSuspended': false,
          'suspensionEndDate': null,
        });

        // Update local state immediately
        setState(() {
          _user = _user!.copyWith(isSuspended: false, suspensionEndDate: null);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Cuenta de ${user.fullName} reactivada exitosamente.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error al reactivar la cuenta: $e')),
          );
        }
      }
    }
  }

  Future<void> _showSendSanctionDialog(
      BuildContext context, app_user.UserModel user) async {
    final TextEditingController messageController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();
    SanctionType selectedSanctionType = SanctionType.warning;

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Enviar Advertencia/Sanción'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Enviando a: ${user.fullName} (${user.email})'),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Mensaje (requerido)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<SanctionType>(
                  initialValue: selectedSanctionType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Sanción',
                    border: OutlineInputBorder(),
                  ),
                  items: SanctionType.values
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.toString().split('.').last),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedSanctionType = value;
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Razón (requerido)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Enviar'),
              onPressed: () async {
                if (messageController.text.isEmpty ||
                    reasonController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                        content: Text('Mensaje y razón son requeridos.')),
                  );
                  return;
                }

                final currentUser = _auth.currentUser;
                if (currentUser == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Admin no autenticado.')),
                  );
                  return;
                }

                try {
                  final sanction = Sanction(
                    id: '', // Will be generated by Firebase
                    userId: user.id,
                    adminId: currentUser.uid,
                    type: selectedSanctionType,
                    message: messageController.text,
                    timestamp: DateTime.now(),
                    reason: reasonController.text,
                  );
                  await _sanctionService.sendSanction(sanction);
                  if (mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                          content: Text('Sanción enviada exitosamente.')),
                    );
                  }
                  Navigator.of(dialogContext).pop();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Error al enviar sanción: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileTab(app_user.UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundImage: user.profilePicture != null
                  ? NetworkImage(user.profilePicture!)
                  : null,
              child: user.profilePicture == null
                  ? const Icon(Icons.person, size: 60)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Nombre Completo:', user.fullName),
          _buildInfoRow('Email:', user.email),
          _buildInfoRow('Tipo de Usuario:', user.userType),
          if (user.publicId != null)
            _buildInfoRow('ID Público:', user.publicId!),
          if (user.phoneNumber != null)
            _buildInfoRow('Teléfono:', user.phoneNumber!),
          if (user.dob != null)
            _buildInfoRow('Fecha de Nacimiento:', user.dob!),
          if (user.placeOfBirth != null)
            _buildInfoRow('Lugar de Nacimiento:', user.placeOfBirth!),
          if (user.rfc != null) _buildInfoRow('RFC:', user.rfc!),
          if (user.gender != null) _buildInfoRow('Sexo:', user.gender!),
          if (user.businessName != null)
            _buildInfoRow('Nombre del Negocio:', user.businessName!),
          if (user.businessAddress != null)
            _buildInfoRow('Dirección del Negocio:', user.businessAddress!),
          if (user.bio != null) _buildInfoRow('Biografía:', user.bio!),
          if (user.paymentInstructions != null)
            _buildInfoRow('Instrucciones de Pago:', user.paymentInstructions!),
          const SizedBox(height: 16),
          if (user.socialMediaLinks != null &&
              user.socialMediaLinks!.isNotEmpty) ...[
            Text('Redes Sociales',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(),
            ...user.socialMediaLinks!.entries.map((entry) {
              return _buildSocialMediaLinkTile(context, entry.key, entry.value);
            }),
          ],
          if (user.isSuspended) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.red.shade100,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.block, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Cuenta Suspendida',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Esta cuenta está suspendida hasta: ${user.suspensionEndDate != null ? DateTime.parse(user.suspensionEndDate!).toLocal().toString().split(' ')[0] : 'Indefinido'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _unsuspendUser(context, user),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Reactivar Cuenta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Builder(
            builder: (context) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'send_sanction') {
                    _showSendSanctionDialog(context, _user!);
                  } else if (value == 'suspend_account') {
                    _showSuspendUserDialog(context, _user!);
                  } else if (value == 'delete_account') {
                    _confirmAndDeleteUser(context, _user!);
                  }
                  // TODO: Add other admin actions here
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'send_sanction',
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber),
                        SizedBox(width: 8),
                        Text('Enviar Advertencia/Sanción'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'suspend_account',
                    child: Row(
                      children: [
                        Icon(Icons.block, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Suspender Cuenta',
                            style: TextStyle(color: Colors.orange)),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete_account',
                    child: Row(
                      children: [
                        Icon(Icons.delete_forever, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar Cuenta',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  // TODO: Add menu items for suspend user, delete user, etc.
                ],
                child: ElevatedButton.icon(
                  onPressed: null, // Disable direct press, use menu
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Acciones Administrativas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSocialMediaLinkTile(
      BuildContext context, String key, String url) {
    IconData icon;
    String title;

    switch (key) {
      case 'facebook':
        icon = FontAwesomeIcons.facebook;
        title = 'Ir a Facebook';
        break;
      case 'instagram':
        icon = FontAwesomeIcons.instagram;
        title = 'Ir a Instagram';
        break;
      case 'tiktok':
        icon = FontAwesomeIcons.tiktok;
        title = 'Ir a TikTok';
        break;
      case 'whatsapp':
        icon = FontAwesomeIcons.whatsapp;
        title = 'Abrir WhatsApp';
        break;
      case 'website':
        icon = Icons.public;
        title = 'Ir al Sitio Web';
        break;
      default:
        icon = Icons.link;
        title = 'Abrir Enlace';
        break;
    }

    return ListTile(
      leading: FaIcon(icon),
      title: Text(title),
      subtitle: Text(url, overflow: TextOverflow.ellipsis),
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo abrir la URL: $url')),
          );
        }
      },
    );
  }
}

class _AdminProductsList extends StatelessWidget {
  final String sellerId;

  const _AdminProductsList({required this.sellerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('products/$sellerId').onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData ||
            !snapshot.data!.snapshot.exists ||
            snapshot.data!.snapshot.value == null) {
          return const Center(
              child: Text('Este vendedor no tiene productos registrados.'));
        }

        final productsMap =
            Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final products = productsMap.entries.map((entry) {
          return Product.fromMap(
              Map<String, dynamic>.from(entry.value as Map), entry.key,
              sellerIdParam: sellerId);
        }).toList();

        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Adjust as needed
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.7,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(
              product: product,
              isAdmin: true, // Display with admin capabilities
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProductDetailsScreen(product: product, isAdmin: true),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AdminPublicationsList extends StatelessWidget {
  final String sellerId;

  const _AdminPublicationsList({required this.sellerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance
          .ref('publications')
          .orderByChild('sellerId')
          .equalTo(sellerId)
          .onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData ||
            !snapshot.data!.snapshot.exists ||
            snapshot.data!.snapshot.value == null) {
          return const Center(
              child: Text('Este vendedor no tiene publicaciones registradas.'));
        }

        final publicationsMap =
            Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final publications = publicationsMap.entries.map((entry) {
          return Publication.fromMap(
              Map<String, dynamic>.from(entry.value as Map), entry.key);
        }).toList();

        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Adjust as needed
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.7,
          ),
          itemCount: publications.length,
          itemBuilder: (context, index) {
            final publication = publications[index];
            return PublicationCard(
              publication: publication,
              sellerName:
                  _getSellerName(publication.sellerId), // Dummy name for now
              sellerProfilePicture: null, // Dummy picture for now
              isAdmin: true, // Display with admin capabilities
              onSellerTap: null, // No seller tap for admin view here
            );
          },
        );
      },
    );
  }

  // Helper to get seller name (might need to fetch from users node)
  String _getSellerName(String sellerId) {
    // In a real scenario, you'd fetch this from the user's data
    // For now, return a placeholder
    return 'Vendedor ${sellerId.substring(0, 6)}';
  }
}
