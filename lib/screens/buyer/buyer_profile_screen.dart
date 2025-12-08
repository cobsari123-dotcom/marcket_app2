import 'package:flutter/material.dart';
import 'package:marcket_app/models/user.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:marcket_app/providers/user_profile_provider.dart';
import 'package:marcket_app/utils/theme.dart';

class BuyerProfileScreen extends StatefulWidget {
  final VoidCallback onProfileUpdated;

  const BuyerProfileScreen({super.key, required this.onProfileUpdated});

  @override
  State<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends State<BuyerProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _rfcController = TextEditingController();
  final TextEditingController _placeOfBirthController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _socialMediaLinkController =
      TextEditingController();
  String? _selectedGender;

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
    final userProfileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final user = userProfileProvider.currentUserModel;

    if (user != null) {
      _fullNameController.text = user.fullName;
      _emailController.text = user.email;
      _phoneNumberController.text = user.phoneNumber ?? '';
      _addressController.text = user.address ?? '';
      _dobController.text = user.dob ?? '';
      _rfcController.text = user.rfc ?? '';
      _placeOfBirthController.text = user.placeOfBirth ?? '';
      _bioController.text = user.bio ?? '';
      _selectedGender = user.gender;

      if (user.socialMediaLinks != null && user.socialMediaLinks!.isNotEmpty) {
        _socialMediaLinkController.text = user.socialMediaLinks!.values.first;
      } else {
        _socialMediaLinkController.text = '';
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _rfcController.dispose();
    _placeOfBirthController.dispose();
    _bioController.dispose();
    _socialMediaLinkController.dispose();
    super.dispose();
  }

  Future<void> _saveUserData() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final userProfileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    try {
      Map<String, String>? socialMediaLinksToSave;
      if (_socialMediaLinkController.text.isNotEmpty) {
        socialMediaLinksToSave = {'default': _socialMediaLinkController.text};
      }

      await userProfileProvider.updateProfile(
        fullName: _fullNameController.text,
        phoneNumber: _phoneNumberController.text,
        address: _addressController.text,
        dob: _dobController.text,
        rfc: _rfcController.text,
        placeOfBirth: _placeOfBirthController.text,
        bio: _bioController.text,
        gender: _selectedGender,
        socialMediaLinks: socialMediaLinksToSave,
      );

      if (mounted) {
        if (userProfileProvider.errorMessage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil actualizado exitosamente.'),
              backgroundColor: AppTheme.success,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: ${userProfileProvider.errorMessage}'),
                backgroundColor: AppTheme.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error inesperado al actualizar: $e'),
              backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, userProfileProvider, child) {
        if (userProfileProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (userProfileProvider.errorMessage != null) {
          return Center(
              child: Text('Error: ${userProfileProvider.errorMessage}'));
        }
        final user = userProfileProvider.currentUserModel;
        if (user == null) {
          return const Center(
              child: Text('No se encontraron datos de usuario.'));
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 80,
                      backgroundImage: user.profilePicture != null
                          ? NetworkImage(user.profilePicture!)
                          : null,
                      backgroundColor: AppTheme.beigeArena,
                      child: user.profilePicture == null
                          ? const Icon(
                              Icons.person,
                              size: 80,
                              color: AppTheme.primary,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(user.email,
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 24),
                    _buildProfileForm(user),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileForm(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(_fullNameController, 'Nombre Completo', Icons.person),
        const SizedBox(height: 16),
        TextFormField(
          controller: _dobController,
          readOnly: true,
          onTap: () => _selectDate(context),
          decoration: const InputDecoration(labelText: 'Fecha de Nacimiento'),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _placeOfBirthController,
          'Lugar de Nacimiento',
          Icons.location_city,
        ),
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
          _addressController,
          'Dirección',
          Icons.location_on,
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _bioController,
          'Biografía',
          Icons.info,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _socialMediaLinkController,
          'Enlace de Red Social (Ej. Facebook, Instagram)',
          Icons.link,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _saveUserData,
          icon: const Icon(Icons.save),
          label: const Text('Guardar Cambios'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
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
        return value!.isEmpty ? 'Por favor, introduce tu $label' : null;
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
      // CORRECCIÓN PRINCIPAL AQUÍ: Se eliminaron los const innecesarios dentro de la lista
      items: const [
        DropdownMenuItem(value: 'Hombre', child: Text('Hombre')),
        DropdownMenuItem(value: 'Mujer', child: Text('Mujer')),
        DropdownMenuItem(
            value: 'Prefiero no decirlo', child: Text('Prefiero no decirlo')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedGender = value;
        });
      },
      validator: (value) =>
          value == null ? 'Por favor selecciona tu sexo' : null,
    );
  }
}
