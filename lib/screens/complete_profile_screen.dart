import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:marcket_app/models/user.dart' as app_user;
import 'package:marcket_app/services/user_service.dart';
import 'package:firebase_database/firebase_database.dart';

class CompleteProfileScreen extends StatefulWidget {
  final User user;
  const CompleteProfileScreen({super.key, required this.user});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedUserType = 'Buyer';
  bool _isSaving = false;

  final _dobController = TextEditingController();
  final _rfcController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _placeOfBirthController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDate;

  // Helper to generate a unique publicId
  Future<String> _generateUniquePublicId(
      String baseName, DatabaseReference usersRef) async {
    String publicIdCandidate = baseName
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^\w\s]'), '');
    if (publicIdCandidate.isEmpty) {
      publicIdCandidate = 'user';
    }

    String finalPublicId = publicIdCandidate;
    int counter = 0;

    // Check for uniqueness in Firebase
    final usersRef = FirebaseDatabase.instance.ref('users');
    while (true) {
      final query = usersRef
          .orderByChild('publicId')
          .equalTo(finalPublicId)
          .limitToFirst(1);
      final snapshot = await query.get();
      if (!snapshot.exists || snapshot.children.isEmpty) {
        return finalPublicId; // Found a unique ID
      }
      counter++;
      finalPublicId = '$publicIdCandidate$counter';
    }
  }

  @override
  void dispose() {
    _dobController.dispose();
    _rfcController.dispose();
    _phoneNumberController.dispose();
    _placeOfBirthController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    super.dispose();
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

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false) || !mounted) return;
    setState(() => _isSaving = true);

    try {
      final DatabaseReference usersRef =
          FirebaseDatabase.instance.ref('users'); // Get reference here
      final String generatedPublicId = await _generateUniquePublicId(
        widget.user.displayName ?? widget.user.email!.split('@').first,
        usersRef, // Pass usersRef
      );

      final newUser = app_user.UserModel(
        id: widget.user.uid,
        fullName: widget.user.displayName ?? 'Sin Nombre',
        email: widget.user.email!,
        userType: _selectedUserType!,
        profilePicture: widget.user.photoURL,
        dob: _dobController.text.trim(),
        rfc: _rfcController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        placeOfBirth: _placeOfBirthController.text.trim(),
        gender: _selectedGender,
        businessName: _selectedUserType == 'Seller'
            ? _businessNameController.text.trim()
            : null,
        businessAddress: _selectedUserType == 'Seller'
            ? _businessAddressController.text.trim()
            : null,
        publicId: generatedPublicId, // Pass generated publicId
      );
      await UserService().setUserData(widget.user.uid, newUser.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('¡Perfil guardado con éxito!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ));
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.of(context).pop(newUser);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al guardar el perfil: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completa tu Perfil'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '¡Bienvenido! Revisa tus datos y completa lo que falta para continuar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUserType,
                    decoration: const InputDecoration(
                        labelText: 'Soy un...', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(
                          value: 'Buyer', child: Text('Comprador')),
                      DropdownMenuItem(
                          value: 'Seller', child: Text('Vendedor')),
                    ],
                    onChanged: (v) => setState(() => _selectedUserType = v),
                    validator: (v) =>
                        v == null ? 'Por favor selecciona un tipo' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneNumberController,
                    decoration:
                        const InputDecoration(labelText: 'Número de Teléfono'),
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v?.isEmpty ?? true)
                        ? 'Ingresa tu número de teléfono'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dobController,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    decoration:
                        const InputDecoration(labelText: 'Fecha de Nacimiento'),
                    validator: (v) => (v?.isEmpty ?? true)
                        ? 'Ingresa tu fecha de nacimiento'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _rfcController,
                    decoration: const InputDecoration(labelText: 'RFC'),
                    validator: (v) => (v?.isEmpty ?? true)
                        ? 'Por favor ingresa tu RFC'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _placeOfBirthController,
                    decoration:
                        const InputDecoration(labelText: 'Lugar de Nacimiento'),
                    validator: (v) => (v?.isEmpty ?? true)
                        ? 'Ingresa tu lugar de nacimiento'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGender,
                    decoration: const InputDecoration(
                        labelText: 'Sexo', border: OutlineInputBorder()),
                    // CORRECCIÓN: Lista constante limpia
                    items: const [
                      DropdownMenuItem(value: 'Hombre', child: Text('Hombre')),
                      DropdownMenuItem(value: 'Mujer', child: Text('Mujer')),
                      DropdownMenuItem(
                          value: 'Prefiero no decirlo',
                          child: Text('Prefiero no decirlo')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Por favor selecciona tu sexo' : null,
                  ),
                  if (_selectedUserType == 'Seller') ...[
                    const SizedBox(height: 24),
                    const Text("Información del Negocio (Vendedor)",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _businessNameController,
                      decoration: const InputDecoration(
                          labelText: 'Nombre del Negocio'),
                      validator: (v) => (v?.isEmpty ?? true)
                          ? 'Ingresa el nombre de tu negocio'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _businessAddressController,
                      decoration: const InputDecoration(
                          labelText: 'Dirección del Negocio'),
                      validator: (v) => (v?.isEmpty ?? true)
                          ? 'Ingresa la dirección de tu negocio'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('GUARDAR Y CONTINUAR'),
                  ),
                  TextButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar y cerrar sesión'),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
