import 'package:flutter/material.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:marcket_app/providers/user_profile_provider.dart';

class BuyerProfileScreen extends StatefulWidget {
  final VoidCallback onProfileUpdated; // Ya no es necesario con Provider, pero lo mantengo por si acaso

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

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Vuelve a poblar si el usuario cambia (ej. cierra sesión y otro inicia sesión)
    _populateFields();
  }

  void _populateFields() {
    final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
    final user = userProfileProvider.currentUserModel;

    if (user != null) {
      _fullNameController.text = user.fullName;
      _emailController.text = user.email;
      _phoneNumberController.text = user.phoneNumber ?? '';
      _addressController.text = user.address ?? '';
      _dobController.text = user.dob ?? '';
      _rfcController.text = user.rfc ?? '';
      _placeOfBirthController.text = user.placeOfBirth ?? '';
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
    super.dispose();
  }

  Future<void> _saveUserData() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
    try {
      await userProfileProvider.updateProfile(
        fullName: _fullNameController.text,
        phoneNumber: _phoneNumberController.text,
        address: _addressController.text,
        dob: _dobController.text,
        rfc: _rfcController.text,
        placeOfBirth: _placeOfBirthController.text,
      );
      if (mounted) {
        if (userProfileProvider.errorMessage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado exitosamente.'), backgroundColor: AppTheme.success),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${userProfileProvider.errorMessage}'), backgroundColor: AppTheme.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado al actualizar: $e'), backgroundColor: AppTheme.error),
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
          return Center(child: Text('Error: ${userProfileProvider.errorMessage}'));
        }
        final user = userProfileProvider.currentUserModel;
        if (user == null) {
          return const Center(child: Text('No se encontraron datos de usuario.'));
        }
        _populateFields(); // Asegurarse de que los campos estén poblados con los datos más recientes

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700), // Limit width for the form
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.beigeArena,
                      backgroundImage: user.profilePicture != null ? NetworkImage(user.profilePicture!) : null,
                      child: user.profilePicture == null
                          ? const Icon(Icons.person, size: 60, color: AppTheme.primary)
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                      validator: (v) => (v == null || v.isEmpty) ? 'Por favor ingresa tu nombre completo' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneNumberController,
                      decoration: const InputDecoration(labelText: 'Número de Teléfono', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder(), prefixIcon: Icon(Icons.home)),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dobController,
                      decoration: const InputDecoration(labelText: 'Fecha de Nacimiento', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _rfcController,
                      decoration: const InputDecoration(labelText: 'RFC', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge)),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _placeOfBirthController,
                      decoration: const InputDecoration(labelText: 'Lugar de Nacimiento', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_city)),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: userProfileProvider.isLoading ? null : _saveUserData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text('Guardar Cambios'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: userProfileProvider.isLoading ? null : () => {}, // TODO: Implementar eliminar cuenta
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text('Eliminar Cuenta'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
