import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marcket_app/models/publication.dart';
import 'package:marcket_app/screens/full_screen_image_viewer.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:marcket_app/widgets/publication_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:marcket_app/providers/user_profile_provider.dart';
import 'package:marcket_app/services/user_service.dart'; // Para _deleteProfilePicture y _updateProfile

class SellerProfileScreen extends StatelessWidget {
  final VoidCallback onProfileUpdated;

  const SellerProfileScreen({super.key, required this.onProfileUpdated});

  @override
  Widget build(BuildContext context) {
    return SellerProfileTabView(); // onProfileUpdated ya no es necesario pasarlo
  }
}

class SellerProfileTabView extends StatefulWidget {
  const SellerProfileTabView({super.key}); // onProfileUpdated ya no es necesario

  @override
  State<SellerProfileTabView> createState() => SellerProfileTabViewState();
}

class SellerProfileTabViewState extends State<SellerProfileTabView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Mi Perfil'),
              Tab(text: 'Mis Publicaciones'),
            ],
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.onBackground.withAlpha(153),
            indicatorColor: AppTheme.primary,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ProfileForm(),
                PublicationsList(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/create_edit_publication'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key});

  @override
  State<ProfileForm> createState() => ProfileFormState();
}

class ProfileFormState extends State<ProfileForm> {
  final _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _placeOfBirthController = TextEditingController();
  final TextEditingController _rfcController = TextEditingController();
  final TextEditingController _paymentInstructionsController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessAddressController = TextEditingController();

  File? _imageFile;
  String? _networkImageUrl;
  bool _isGoogleUser = false;

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _populateFields();
  }

  void _populateFields() {
    final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
    final user = userProfileProvider.currentUserModel;

    if (user != null) {
      _fullNameController.text = user.fullName;
      _dobController.text = user.dob ?? '';
      _placeOfBirthController.text = user.placeOfBirth ?? '';
      _rfcController.text = user.rfc ?? '';
      _networkImageUrl = user.profilePicture;
      _paymentInstructionsController.text = user.paymentInstructions ?? '';
      _phoneNumberController.text = user.phoneNumber ?? '';
      _businessNameController.text = user.businessName ?? '';
      _businessAddressController.text = user.businessAddress ?? '';
      _isGoogleUser = _auth.currentUser?.providerData.any(
        (p) => p.providerId == 'google.com',
      ) ?? false;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedImage == null || !mounted) return;
    
    setState(() {
      _imageFile = File(pickedImage.path);
    });

    try {
      final storageRef = FirebaseStorage.instance.ref(
        'profile_pictures/${_auth.currentUser!.uid}.jpg',
      );
      final imageData = await _imageFile!.readAsBytes();
      UploadTask uploadTask = storageRef.putData(
        imageData,
        SettableMetadata(contentType: "image/jpeg"),
      );
      final snapshot = await uploadTask;
      final downloadURL = await snapshot.ref.getDownloadURL();

      await _auth.currentUser?.updatePhotoURL(downloadURL);
      await _userService.updateUserData(_auth.currentUser!.uid, {
        'profilePicture': downloadURL,
      });

      if (!mounted) return;
      setState(() => _networkImageUrl = downloadURL);
      _showSnackBar('¡Foto de perfil actualizada!');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error al subir la imagen: $e', isError: true);
    }
  }

  Future<void> _syncPhotoFromGoogle() async {
    try {
      await _auth.currentUser?.reload();
      final newPhotoUrl = _auth.currentUser?.photoURL;
      await _userService.updateUserData(_auth.currentUser!.uid, {
        'profilePicture': newPhotoUrl,
      });
      if (mounted) {
        setState(() => _networkImageUrl = newPhotoUrl);
        _showSnackBar('Foto de perfil sincronizada con Google.');
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error al sincronizar la foto: $e', isError: true);
    }
  }

  Future<void> _manageInGoogle() async {
    final url = Uri.parse('https://myaccount.google.com/personal-info');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) _showSnackBar('No se pudo abrir el navegador.', isError: true);
    }
  }

  Future<void> _deleteProfilePicture() async {
    if (_networkImageUrl == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Foto'),
        content: Text(
          _isGoogleUser
              ? 'Esto quitará tu foto de la app, pero no de tu cuenta de Google.'
              : '¿Estás seguro?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar', style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );

    if (confirmed != true) return;
    
    try {
      if (!_isGoogleUser) {
        await FirebaseStorage.instance.refFromURL(_networkImageUrl!).delete();
      }
      await _userService.updateUserData(_auth.currentUser!.uid, {
        'profilePicture': null,
      });
      if (!_isGoogleUser) {
        await _auth.currentUser?.updatePhotoURL(null);
      }
      if (mounted) {
        setState(() {
          _networkImageUrl = null;
          _imageFile = null;
        });
        _showSnackBar('Foto de perfil eliminada.');
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error al eliminar la foto: $e', isError: true);
    } finally {
      // No hay estado de carga que desactivar aquí
    }
  }

  Future<void> _updateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
    try {
      await userProfileProvider.updateProfile(
        fullName: _fullNameController.text,
        dob: _dobController.text,
        placeOfBirth: _placeOfBirthController.text,
        rfc: _rfcController.text,
        paymentInstructions: _paymentInstructionsController.text,
        phoneNumber: _phoneNumberController.text,
        businessName: _businessNameController.text,
        businessAddress: _businessAddressController.text,
      );
      if (mounted) {
        if (userProfileProvider.errorMessage == null) {
          _showSnackBar('¡Perfil actualizado con éxito!');
        } else {
          _showSnackBar('Error: ${userProfileProvider.errorMessage}', isError: true);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error al actualizar el perfil: $e', isError: true);
    }
  }

  void _showProfilePictureMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            if (_networkImageUrl != null)
              ListTile(
                leading: const Icon(Icons.fullscreen),
                title: const Text('Ver Foto'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImageViewer(imageUrl: _networkImageUrl!),
                    ),
                  );
                },
              ),
            if (_isGoogleUser) ...[
              ListTile(
                leading: const Icon(Icons.manage_accounts),
                title: const Text('Gestionar en Google'),
                onTap: () {
                  Navigator.pop(context);
                  _manageInGoogle();
                },
              ),
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Sincronizar con Google'),
                onTap: () {
                  Navigator.pop(context);
                  _syncPhotoFromGoogle();
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cambiar Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage();
                },
              ),
            ],
            if (_networkImageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.error),
                title: const Text(
                  'Eliminar Foto',
                  style: TextStyle(color: AppTheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteProfilePicture();
                },
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, userProfileProvider, child) {
        if (userProfileProvider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        if (userProfileProvider.errorMessage != null) {
          return Center(child: Text('Error: ${userProfileProvider.errorMessage}'));
        }
        final user = userProfileProvider.currentUserModel;
        if (user == null) {
          return const Center(child: Text('No se encontraron datos de usuario.'));
        }

        // Asegurarse de que los controladores estén actualizados al construir la UI
        _fullNameController.text = user.fullName;
        _dobController.text = user.dob ?? '';
        _placeOfBirthController.text = user.placeOfBirth ?? '';
        _rfcController.text = user.rfc ?? '';
        _paymentInstructionsController.text = user.paymentInstructions ?? '';
        _phoneNumberController.text = user.phoneNumber ?? '';
        _businessNameController.text = user.businessName ?? '';
        _businessAddressController.text = user.businessAddress ?? '';
        _networkImageUrl = user.profilePicture;
        _isGoogleUser = _auth.currentUser?.providerData.any(
          (p) => p.providerId == 'google.com',
        ) ?? false;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700), // Limit width for the form
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildProfileForm(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader() {
    final userProfileProvider = Provider.of<UserProfileProvider>(context);
    final user = userProfileProvider.currentUserModel;

    return Column(
      children: [
        GestureDetector(
          onTap: _showProfilePictureMenu,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 80,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : (_networkImageUrl != null
                              ? NetworkImage(_networkImageUrl!)
                              : null)
                          as ImageProvider?,
                backgroundColor: AppTheme.beigeArena,
                child: _imageFile == null && _networkImageUrl == null
                    ? const Icon(
                        Icons.store, // Icono de tienda para vendedor
                        size: 80,
                        color: AppTheme.primary,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: AppTheme.secondary,
                  child: const Icon(Icons.camera_alt, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user?.fullName ?? '',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(user?.email ?? '', style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(_fullNameController, 'Nombre Completo', Icons.person),
          const SizedBox(height: 16),
          _buildTextField(
            _dobController,
            'Fecha de Nacimiento',
            Icons.calendar_today,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _placeOfBirthController,
            'Lugar de Nacimiento',
            Icons.location_city,
          ),
          const SizedBox(height: 16),
          _buildTextField(_rfcController, 'RFC', Icons.badge),
          const SizedBox(height: 16),
          _buildTextField(
            _phoneNumberController,
            'Número de Teléfono',
            Icons.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _businessNameController,
            'Nombre del Negocio',
            Icons.business,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _businessAddressController,
            'Dirección del Negocio',
            Icons.location_on,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _paymentInstructionsController,
            'Instrucciones de Pago',
            Icons.payment,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _updateProfile,
            icon: const Icon(Icons.save),
            label: const Text('Guardar Cambios'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary),
      ),
      validator: (value) {
        if (label == 'Instrucciones de Pago') {
          return null;
        }
        return value!.isEmpty ? 'Por favor, introduce tu $label' : null;
      },
    );
  }
}

class PublicationsList extends StatefulWidget {
  final String? title;
  const PublicationsList({super.key, this.title});

  @override
  PublicationsListState createState() => PublicationsListState();
}

class PublicationsListState extends State<PublicationsList> {
  final _database = FirebaseDatabase.instance.ref();
  final _userId = FirebaseAuth.instance.currentUser!.uid;
  String _sellerName = 'Mi Perfil';
  String? _sellerProfilePicture;

  @override
  void initState() {
    super.initState();
    _loadSellerData();
  }

  Future<void> _loadSellerData() async {
    final snapshot = await _database.child('users/$_userId').get();
    if (snapshot.exists && mounted) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _sellerName = data['fullName'] ?? 'Mi Perfil';
        _sellerProfilePicture = data['profilePicture'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.title!,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        Expanded(
          child: StreamBuilder(
            stream: _database
                .child('publications')
                .orderByChild('sellerId')
                .equalTo(_userId)
                .onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.article_outlined,
                        size: 80,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Aún no tienes publicaciones.',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Usa el botón "+" para crear una nueva historia.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final data = Map<String, dynamic>.from(
                snapshot.data!.snapshot.value as Map,
              );
              final publications = data.entries.map((entry) {
                return Publication.fromMap(
                  Map<String, dynamic>.from(entry.value as Map),
                  entry.key,
                );
              }).toList();

              publications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

              return LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  int crossAxisCount;
                  if (screenWidth > 1200) {
                    crossAxisCount = 5;
                  } else if (screenWidth > 900) {
                    crossAxisCount = 4;
                  } else if (screenWidth > 600) {
                    crossAxisCount = 3;
                  } else {
                    crossAxisCount = 2;
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 0.70,
                    ),
                    itemCount: publications.length,
                    itemBuilder: (context, index) {
                      final publication = publications[index];
                      return PublicationCard(
                        publication: publication,
                        sellerName: _sellerName,
                        sellerProfilePicture: _sellerProfilePicture,
                        onSellerTap: () {},
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}