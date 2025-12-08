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
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement admin actions like suspend user, reset password, etc.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Acciones de administrador próximamente.')),
              );
            },
            icon: const Icon(Icons.admin_panel_settings),
            label: const Text('Realizar Acción Administrativa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
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
