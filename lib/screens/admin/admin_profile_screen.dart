import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/screens/recover_password_screen.dart';
import 'package:marcket_app/utils/theme.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance.ref();
  User? _user;
  UserModel? _userModel;

  final _fullNameController = TextEditingController();
  
  bool _isLoading = true;
  int _totalUsers = 0;
  int _totalPublications = 0;
  int _totalProducts = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadAllData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (mounted) setState(() => _isLoading = true);
    if (_user != null) {
      try {
        final userSnapshot = await _database.child('users/${_user!.uid}').get();
        final usersCountSnapshot = await _database.child('users').get();
        final publicationsCountSnapshot = await _database.child('publications').get();
        final productsCountSnapshot = await _database.child('products').get();

        if (mounted) {
          if (userSnapshot.exists) {
            _userModel = UserModel.fromMap(Map<String, dynamic>.from(userSnapshot.value as Map), _user!.uid);
            _fullNameController.text = _userModel?.fullName ?? '';
          }
          _totalUsers = usersCountSnapshot.children.length;
          _totalPublications = publicationsCountSnapshot.children.length;
          
          int productCount = 0;
          if (productsCountSnapshot.exists) {
            final productsData = Map<String, dynamic>.from(productsCountSnapshot.value as Map);
            productsData.forEach((sellerId, products) {
              productCount += (products as Map).length;
            });
          }
          _totalProducts = productCount;

          setState(() {});
          _animationController.forward();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar datos: ${e.toString()}'), backgroundColor: AppTheme.error),
          );
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _updateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _user?.updateDisplayName(_fullNameController.text);
      await _database.child('users/${_user!.uid}').update({
        'fullName': _fullNameController.text,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Perfil actualizado con éxito!'), backgroundColor: AppTheme.success),
      );
      _loadAllData(); // Recargar datos
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el perfil: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 250.0,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(_userModel?.fullName ?? 'Perfil de Admin', style: const TextStyle(shadows: [Shadow(blurRadius: 5)])),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          color: AppTheme.primary,
                          child: Icon(Icons.shield, size: 100, color: Colors.white54),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withAlpha((255 * 0.7).round())],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatsCard(),
                          const SizedBox(height: 24),
                          _buildProfileForm(),
                          const SizedBox(height: 24),
                          _buildSecurityCard(context),
                          const SizedBox(height: 24),
                          _buildInfoCard(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSecurityCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seguridad', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.lock, color: AppTheme.secondary),
              title: const Text('Cambiar Contraseña'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RecoverPasswordScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(icon: Icons.people, label: 'Usuarios', value: _totalUsers.toString()),
            _StatItem(icon: Icons.article, label: 'Posts', value: _totalPublications.toString()),
            _StatItem(icon: Icons.store, label: 'Productos', value: _totalProducts.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Editar Información', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  prefixIcon: Icon(Icons.person, color: AppTheme.primary),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value?.isEmpty ?? true) ? 'Por favor, introduce tu nombre' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _updateProfile,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Cambios'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detalles de la Cuenta', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.email, color: AppTheme.secondary),
              title: Text(_user?.email ?? 'No disponible'),
            ),
            ListTile(
              leading: const Icon(Icons.shield, color: AppTheme.secondary),
              title: const Text('Rol'),
              subtitle: Text(_userModel?.userType ?? 'Admin'),
            ),
            ListTile(
              leading: const Icon(Icons.date_range, color: AppTheme.secondary),
              title: const Text('Miembro desde'),
              subtitle: Text(
                _user?.metadata.creationTime != null 
                ? DateFormat('dd MMMM, yyyy', 'es_ES').format(_user!.metadata.creationTime!) 
                : 'No disponible'
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 30, color: AppTheme.primary),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
