import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:marcket_app/models/user.dart' as app_user;
import 'package:marcket_app/services/auth_service.dart';
import 'package:marcket_app/services/user_service.dart';
import 'package:marcket_app/screens/complete_profile_screen.dart';

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

    if (userModel != null) {
      // User exists in DB, navigate to their respective dashboard
      _navigateUser(userModel.userType);
    } else {
      // User does NOT exist in DB, check if their email is on the admin whitelist
      final isAdminByEmail = await _userService.isAdminEmail(user.email!);
      if (isAdminByEmail) {
        // This is a potential admin. Ask for the secret key.
        final bool? codeVerified = await _showAdminKeyCodeDialog();
        if (codeVerified == true) {
          // Key is correct, create their admin profile on the fly
          final newAdmin = app_user.UserModel(
            id: user.uid,
            fullName: user.displayName ?? 'Admin',
            email: user.email!,
            userType: 'admin',
            profilePicture: user.photoURL,
          );
          await _userService.setUserData(user.uid, newAdmin.toMap());
          if (mounted) _navigateUser('admin');
        } else {
          // Key is incorrect or dialog was cancelled, sign out
          await _authService.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('La clave de administrador es incorrecta.'),
              backgroundColor: AppTheme.error,
            ));
          }
        }
      } else if (isGoogleSignIn) {
        // If it was a Google Sign-In by a non-admin new user, prompt to complete profile
        await _navigateToCompleteProfile(user);
      } else {
        // If it was a manual email/password sign-in and the user is not in DB and not an admin, deny access
        await _authService.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Este usuario no está registrado. Por favor, regístrese o contacte a soporte.'),
            backgroundColor: AppTheme.error,
          ));
        }
      }
    }
  }

  Future<bool?> _showAdminKeyCodeDialog() async {
    final TextEditingController keyController = TextEditingController();
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Verificación de Administrador'),
          content: TextField(
            controller: keyController,
            autofocus: true,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Clave de Administrador',
              hintText: 'Ingresa la clave secreta',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final bool isCorrect = keyController.text.trim() == '12345678';
                Navigator.of(context).pop(isCorrect);
              },
              child: const Text('Verificar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToCompleteProfile(User user) async {
    if (!mounted) return;
    // Navigate to the new screen instead of showing a dialog
    final result = await Navigator.push(
      context,
      MaterialPageRoute<app_user.UserModel>(
        builder: (context) => CompleteProfileScreen(user: user),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      _navigateUser(result.userType);
    } else {
      // If the user cancelled (e.g., pressed back or the cancel button), sign them out.
      try {
        await user.delete(); // Also delete the partially created user from Auth
      } catch (e) {
        // This might fail if re-authentication is required, but we can fail silently.
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
      'admin' => '/admin_dashboard', // Correct route for admin
      'Buyer' => '/buyer_dashboard', // Correct route
      'Seller' => '/seller_dashboard', // Correct route
      _ => null
    };
    if (route != null) {
      Navigator.pushReplacementNamed(context, route);
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
        constraints: const BoxConstraints(maxWidth: 450),
        child: Card(
          margin: const EdgeInsets.all(24.0),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            child: _buildLoginForm(),
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
          ).animate().fade(delay: 1100.ms),
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