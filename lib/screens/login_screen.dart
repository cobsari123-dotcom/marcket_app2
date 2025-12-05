import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:marcket_app/models/user.dart' as app_user;
import 'package:marcket_app/services/auth_service.dart';
import 'package:marcket_app/services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  bool _isLoading = false;
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false) || !mounted) return;
    setState(() => _isLoading = true);
    try {
      final userCredential = await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted && userCredential.user != null) {
        await _handleSuccessfulLogin(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _handleAuthError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      
      if (mounted && userCredential.user != null) {
        await _handleSuccessfulLogin(userCredential.user!, isGoogleSignIn: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al iniciar sesión con Google: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSuccessfulLogin(User user, {bool isGoogleSignIn = false}) async {
    final userModel = await _userService.getUserById(user.uid);

    if (!mounted) return;

    if (userModel != null) {
      _navigateUser(userModel.userType);
    } else if (isGoogleSignIn) {
      // Check if the user is a whitelisted admin
      final isAdmin = await _userService.isAdminEmail(user.email!);
      if (isAdmin) {
        final newAdmin = app_user.UserModel(
          id: user.uid,
          fullName: user.displayName ?? 'Admin Sin Nombre',
          email: user.email!,
          userType: 'admin',
          profilePicture: user.photoURL,
        );
        await _userService.setUserData(user.uid, newAdmin.toMap());
        if (mounted) _navigateUser('admin');
      } else {
        await _showCompleteProfileDialog(user);
      }
    } else {
      await _authService.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se encontraron datos de usuario.'),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  Future<void> _showCompleteProfileDialog(User user) async {
    if (!mounted) return;
    final result = await showDialog<app_user.UserModel>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => CompleteProfileDialog(user: user),
    );
    if (!mounted) return;
    if (result != null) {
      _navigateUser(result.userType);
    } else {
      try {
        await user.delete();
      } catch (e) {
        // Silently fail
      }
      await _authService.signOut();
    }
  }

  void _navigateUser(String? userType) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('¡Inicio de sesión exitoso!'),
      duration: Duration(seconds: 2),
      backgroundColor: AppTheme.success,
    ));
    final route = switch (userType) {
      'admin' => '/admin_home',
      'Buyer' || 'Seller' => '/home',
      _ => null
    };
    if (route != null) {
      Navigator.pushReplacementNamed(context, route, arguments: userType);
    } else {
      _authService.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tipo de usuario desconocido o no especificado.'),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    String errorMessage = 'Ocurrió un error';
    if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
      errorMessage = 'Correo electrónico o contraseña incorrectos.';
    } else {
      errorMessage = e.message ?? errorMessage;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (El resto del build method se mantiene igual)
    return Scaffold(
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return _buildWideLayout();
              } else {
                return _buildNarrowLayout();
              }
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(128),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _buildLoginForm(),
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Card(
          margin: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(32.0),
                  color: AppTheme.primary,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/logoapp.jpg', width: 120),
                      const SizedBox(height: 24),
                      Text(
                        'Manos del Mar',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.onPrimary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Conectando artesanos, inspirando al mundo.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.onPrimary.withAlpha(204)),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                  child: _buildLoginForm(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Image.asset('assets/images/logoapp.jpg', height: 80),
          const SizedBox(height: 32),
          Text(
            '¡Bienvenido de Nuevo!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ).animate().fade(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Ingresa tus credenciales para continuar',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ).animate().fade(delay: 300.ms),
          const SizedBox(height: 40.0),
          _buildEmailField().animate().fade(delay: 400.ms).slideY(begin: 0.2),
          const SizedBox(height: 20.0),
          _buildPasswordField().animate().fade(delay: 500.ms).slideY(begin: 0.2),
          const SizedBox(height: 16.0),
          _buildForgotPasswordLink().animate().fade(delay: 600.ms),
          const SizedBox(height: 24.0),
          _buildLoginButton().animate().fade(delay: 700.ms).slideY(begin: 0.2),
          const SizedBox(height: 20.0),
          _buildOrDivider().animate().fade(delay: 800.ms),
          const SizedBox(height: 20.0),
          _buildGoogleSignInButton().animate().fade(delay: 900.ms).slideY(begin: 0.2),
          const SizedBox(height: 32.0),
          _buildRegisterLink().animate().fade(delay: 1000.ms),
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            child: const Text('Volver a la Bienvenida'),
          ).animate().fade(delay: 1100.ms), // Add a slight delay for animation
        ],
      ),
    );
  }

  Widget _buildEmailField() => TextFormField(
        controller: _emailController,
        decoration: const InputDecoration(labelText: 'Correo Electrónico', prefixIcon: Icon(Icons.email_outlined)),
        keyboardType: TextInputType.emailAddress,
        validator: (v) => (v?.isEmpty ?? true) ? 'Por favor ingresa tu correo' : null,
      );

  Widget _buildPasswordField() => TextFormField(
        controller: _passwordController,
        obscureText: _obscureText,
        decoration: InputDecoration(
          labelText: 'Contraseña',
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(_obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: () => setState(() => _obscureText = !_obscureText),
          ),
        ),
        validator: (v) => (v?.isEmpty ?? true) ? 'Por favor ingresa tu contraseña' : null,
      );

  Widget _buildForgotPasswordLink() => Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => Navigator.pushNamed(context, '/recover_password'),
          child: const Text('¿Olvidaste tu Contraseña?'),
        ),
      );

  Widget _buildLoginButton() => ElevatedButton(
        onPressed: _isLoading ? null : _login,
        child: const Text('INICIAR SESIÓN'),
      );

  Widget _buildGoogleSignInButton() => OutlinedButton.icon(
        icon: const FaIcon(FontAwesomeIcons.google, size: 18),
        label: const Text('Continuar con Google'),
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withAlpha(51)),
        ),
      );

  Widget _buildOrDivider() => const Row(
        children: [
          Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('O', style: TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Divider()),
        ],
      );

  Widget _buildRegisterLink() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('¿No tienes una cuenta?'),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/register'),
            child: const Text('Regístrate'),
          ),
        ],
      );
}

class CompleteProfileDialog extends StatefulWidget {
  final User user;
  const CompleteProfileDialog({super.key, required this.user});
  @override
  State<CompleteProfileDialog> createState() => CompleteProfileDialogState();
}

class CompleteProfileDialogState extends State<CompleteProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedUserType;
  bool _isSaving = false;

  final _dobController = TextEditingController();
  final _rfcController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _placeOfBirthController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  DateTime? _selectedDate;
  
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
        businessName: _selectedUserType == 'Seller' ? _businessNameController.text.trim() : null,
        businessAddress: _selectedUserType == 'Seller' ? _businessAddressController.text.trim() : null,
      );
      await UserService().setUserData(widget.user.uid, newUser.toMap());
      if (mounted) Navigator.of(context).pop(newUser);
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
    // ... (El resto del build method se mantiene igual)
    return AlertDialog(
      title: const Text('Completa tu Perfil'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¡Bienvenido! Revisa tus datos y completa lo que falta.'),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _selectedUserType,
                decoration: const InputDecoration(labelText: 'Soy un...', border: OutlineInputBorder()),
                items: ['Buyer', 'Seller'].map((v) => DropdownMenuItem(value: v, child: Text(v == 'Buyer' ? 'Comprador' : 'Vendedor'))).toList(),
                onChanged: (v) => setState(() => _selectedUserType = v),
                validator: (v) => v == null ? 'Por favor selecciona un tipo' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(labelText: 'Número de Teléfono'),
                keyboardType: TextInputType.phone,
                validator: (v) => (v?.isEmpty ?? true) ? 'Ingresa tu número de teléfono' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dobController,
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: const InputDecoration(labelText: 'Fecha de Nacimiento'),
                validator: (v) => (v?.isEmpty ?? true) ? 'Ingresa tu fecha de nacimiento' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rfcController,
                decoration: const InputDecoration(labelText: 'RFC'),
                validator: (v) => (v?.isEmpty ?? true) ? 'Por favor ingresa tu RFC' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _placeOfBirthController,
                decoration: const InputDecoration(labelText: 'Lugar de Nacimiento'),
                validator: (v) => (v?.isEmpty ?? true) ? 'Ingresa tu lugar de nacimiento' : null,
              ),
              if (_selectedUserType == 'Seller') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(labelText: 'Nombre del Negocio'),
                  validator: (v) => (v?.isEmpty ?? true) ? 'Ingresa el nombre de tu negocio' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _businessAddressController,
                  decoration: const InputDecoration(labelText: 'Dirección del Negocio'),
                  validator: (v) => (v?.isEmpty ?? true) ? 'Ingresa la dirección de tu negocio' : null,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isSaving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveProfile,
          child: _isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('REGISTRARME'),
        ),
      ],
    );
  }
}
