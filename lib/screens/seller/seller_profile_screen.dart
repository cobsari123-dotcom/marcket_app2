import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:marcket_app/screens/full_screen_image_viewer.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:marcket_app/providers/user_profile_provider.dart';
import 'package:marcket_app/services/user_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SellerProfileScreen extends StatelessWidget {
  final VoidCallback onProfileUpdated;

  const SellerProfileScreen({super.key, required this.onProfileUpdated});

  @override
  Widget build(BuildContext context) {
    return ProfileForm(onProfileUpdated: onProfileUpdated);
  }
}

class ProfileForm extends StatefulWidget {
  final VoidCallback onProfileUpdated;
  const ProfileForm({super.key, required this.onProfileUpdated});

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
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _tiktokController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDate;

  File? _imageFile;
  String? _networkImageUrl;
  bool _isGoogleUser = false;
  bool _isLoadingImage = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _placeOfBirthController.dispose();
    _rfcController.dispose();
    _paymentInstructionsController.dispose();
    _phoneNumberController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _bioController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _whatsappController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _selectedDate) {
      if (!mounted) return;
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
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
      _bioController.text = user.bio ?? '';
      _selectedGender = user.gender;

      _facebookController.text = user.socialMediaLinks?['facebook'] ?? '';
      _instagramController.text = user.socialMediaLinks?['instagram'] ?? '';
      _tiktokController.text = user.socialMediaLinks?['tiktok'] ?? '';
      _whatsappController.text = user.socialMediaLinks?['whatsapp'] ?? '';
      _websiteController.text = user.socialMediaLinks?['website'] ?? '';

      _isGoogleUser = _auth.currentUser?.providerData.any(
        (p) => p.providerId == 'google.com',
      ) ?? false;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    if (_isGoogleUser) {
      _showSnackBar('Los usuarios de Google gestionan su foto desde su cuenta de Google.', isError: true);
      return;
    }
    
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedImage == null || !mounted) return;
    
    setState(() {
      _imageFile = File(pickedImage.path);
      _isLoadingImage = true;
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
    } finally {
      if (mounted) setState(() => _isLoadingImage = false);
      widget.onProfileUpdated();
    }
  }

  Future<void> _syncPhotoFromGoogle() async {
    if (!mounted) return;
    if (!_isGoogleUser) {
      _showSnackBar('Esta opción es solo para usuarios registrados con Google.', isError: true);
      return;
    }
    setState(() => _isLoadingImage = true);
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
    } finally {
      if (mounted) setState(() => _isLoadingImage = false);
      widget.onProfileUpdated();
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
    
    setState(() => _isLoadingImage = true);

    try {
      if (!_isGoogleUser) {
        await FirebaseStorage.instance.refFromURL(_networkImageUrl!).delete();
      }
      await _userService.updateUserData(_auth.currentUser!.uid, {
        'profilePicture': null,
      });
      await _auth.currentUser?.updatePhotoURL(null);

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
      if (mounted) setState(() => _isLoadingImage = false);
      widget.onProfileUpdated();
    }
  }

  Future<void> _updateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
    try {
      final Map<String, String> socialMediaLinksToSave = {};
      if (_facebookController.text.isNotEmpty) socialMediaLinksToSave['facebook'] = _facebookController.text;
      if (_instagramController.text.isNotEmpty) socialMediaLinksToSave['instagram'] = _instagramController.text;
      if (_tiktokController.text.isNotEmpty) socialMediaLinksToSave['tiktok'] = _tiktokController.text;
      if (_whatsappController.text.isNotEmpty) socialMediaLinksToSave['whatsapp'] = _whatsappController.text;
      if (_websiteController.text.isNotEmpty) socialMediaLinksToSave['website'] = _websiteController.text;

      await userProfileProvider.updateProfile(
        fullName: _fullNameController.text,
        dob: _dobController.text,
        placeOfBirth: _placeOfBirthController.text,
        rfc: _rfcController.text,
        paymentInstructions: _paymentInstructionsController.text,
        phoneNumber: _phoneNumberController.text,
        businessName: _businessNameController.text,
        businessAddress: _businessAddressController.text,
        bio: _bioController.text,
        gender: _selectedGender,
        socialMediaLinks: socialMediaLinksToSave,
      );
      if (mounted) {
        if (userProfileProvider.errorMessage == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('¡Perfil actualizado con éxito!'),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 3),
          ));
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
              if (_networkImageUrl != null)
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('Sincronizar con Google'),
                  onTap: () {
                    Navigator.pop(context);
                    _syncPhotoFromGoogle();
                  },
                ),
            ] else
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cambiar Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage();
                },
              ),
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
          return const Center(child: CircularProgressIndicator());
        }
        if (userProfileProvider.errorMessage != null) {
          return Center(child: Text('Error: ${userProfileProvider.errorMessage}'));
        }
        final user = userProfileProvider.currentUserModel;
        if (user == null) {
          return const Center(child: Text('No se encontraron datos de usuario.'));
        }

        _fullNameController.text = user.fullName;
        _dobController.text = user.dob ?? '';
        _placeOfBirthController.text = user.placeOfBirth ?? '';
        _rfcController.text = user.rfc ?? '';
        _paymentInstructionsController.text = user.paymentInstructions ?? '';
        _phoneNumberController.text = user.phoneNumber ?? '';
        _businessNameController.text = user.businessName ?? '';
        _businessAddressController.text = user.businessAddress ?? '';
        _networkImageUrl = user.profilePicture;
        _bioController.text = user.bio ?? '';
        _selectedGender = user.gender;

        _facebookController.text = user.socialMediaLinks?['facebook'] ?? '';
        _instagramController.text = user.socialMediaLinks?['instagram'] ?? '';
        _tiktokController.text = user.socialMediaLinks?['tiktok'] ?? '';
        _whatsappController.text = user.socialMediaLinks?['whatsapp'] ?? '';
        _websiteController.text = user.socialMediaLinks?['website'] ?? '';

        _isGoogleUser = _auth.currentUser?.providerData.any(
          (p) => p.providerId == 'google.com',
        ) ?? false;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
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
                child: _imageFile == null && _networkImageUrl == null && _isLoadingImage == false
                    ? const Icon(
                        Icons.store,
                        size: 80,
                        color: AppTheme.primary,
                      )
                    : (_isLoadingImage ? const CircularProgressIndicator() : null),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: _isLoadingImage
                    ? const SizedBox.shrink()
                    : CircleAvatar(
                        backgroundColor: AppTheme.secondary,
                        child: Icon(
                          _isGoogleUser ? Icons.settings : Icons.camera_alt,
                          color: Colors.white,
                        ),
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
          _buildDateField(),
          const SizedBox(height: 16),
          _buildGenderSelector(),
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
          const SizedBox(height: 24),
          Text('Redes Sociales', style: Theme.of(context).textTheme.titleLarge),
          const Divider(),
          const SizedBox(height: 16),
          _buildSocialMediaTextField(_facebookController, 'Facebook', FontAwesomeIcons.facebook, 'https://facebook.com/usuario'),
          const SizedBox(height: 16),
          _buildSocialMediaTextField(_instagramController, 'Instagram', FontAwesomeIcons.instagram, 'https://instagram.com/usuario'),
          const SizedBox(height: 16),
          _buildSocialMediaTextField(_tiktokController, 'TikTok', FontAwesomeIcons.tiktok, 'https://tiktok.com/@usuario'),
          const SizedBox(height: 16),
          _buildSocialMediaTextField(_whatsappController, 'WhatsApp', FontAwesomeIcons.whatsapp, 'https://wa.me/numero'),
          const SizedBox(height: 16),
          _buildSocialMediaTextField(_websiteController, 'Sitio Web/Otros', Icons.link, 'https://ejemplo.com'),
          const SizedBox(height: 16),
          _buildTextField(
            _bioController,
            'Biografía',
            Icons.info,
            maxLines: 3,
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
    bool isSocialMedia = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary),
      ),
      validator: (value) {
        if (isSocialMedia && value != null && value.isNotEmpty) {
          if (Uri.tryParse(value)?.hasAbsolutePath != true) {
            return 'Por favor, ingresa una URL válida.';
          }
        }
        if (label == 'Instrucciones de Pago' || label == 'Biografía') {
          return null;
        }
        return value!.isEmpty ? 'Por favor, introduce tu $label' : null;
      },
    );
  }

  Widget _buildSocialMediaTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    String hintText,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppTheme.primary),
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          if (Uri.tryParse(value)?.hasAbsolutePath != true) {
            return 'Por favor, ingresa una URL válida.';
          }
        }
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _dobController,
      readOnly: true,
      onTap: () => _selectDate(context),
      decoration: const InputDecoration(
        labelText: 'Fecha de Nacimiento',
        prefixIcon: Icon(Icons.calendar_today, color: AppTheme.primary),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor selecciona tu fecha de nacimiento';
        }
        return null;
      },
    );
  }

  Widget _buildGenderSelector() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedGender,
      decoration: const InputDecoration(
        labelText: 'Sexo',
        prefixIcon: Icon(Icons.wc, color: AppTheme.primary),
      ),
      // CORRECCIÓN: Lista constante
      items: const [
        DropdownMenuItem(value: 'Hombre', child: Text('Hombre')),
        DropdownMenuItem(value: 'Mujer', child: Text('Mujer')),
        DropdownMenuItem(value: 'Prefiero no decirlo', child: Text('Prefiero no decirlo')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedGender = value;
        });
      },
      validator: (value) => value == null ? 'Por favor selecciona tu sexo' : null,
    );
  }
}