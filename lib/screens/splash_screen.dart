import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:marcket_app/utils/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    _initSplash();
  }

  void _initSplash() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      Future.delayed(const Duration(seconds: 2), () {
        _navigate(user);
      });
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _navigate(User? user) async {
    if (!mounted) return;

    if (user != null) {
      try {
        final snapshot = await FirebaseDatabase.instance.ref('users/${user.uid}').get();
        if (mounted && snapshot.exists) {
          final userData = Map<String, dynamic>.from(snapshot.value as Map);
          final userType = userData['userType'] as String?;
          Navigator.pushReplacementNamed(context, '/home', arguments: userType ?? 'Buyer');
        } else {
          await FirebaseAuth.instance.signOut();
          if (mounted) Navigator.pushReplacementNamed(context, '/');
        }
      } catch (e) {
        await FirebaseAuth.instance.signOut();
        if (mounted) Navigator.pushReplacementNamed(context, '/');
      }
    } else {
      if (mounted) Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.verdeAguaSuave],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600), // Limit width for larger screens
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logoapp.jpg',
                      width: size.width * 0.5, // Keep width relative to screen width within constraints
                      fit: BoxFit.contain,
                    )
                        .animate()
                        .fade(duration: 1500.ms)
                        .scale(delay: 500.ms, duration: 1000.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 20),
                    Text(
                      'Manos del Mar',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                          ),
                    )
                        .animate()
                        .fade(duration: 1500.ms, delay: 1000.ms)
                        .slideY(begin: 0.5, end: 0, duration: 1000.ms, curve: Curves.easeOut),
                    const SizedBox(height: 10),
                    Text(
                      'Hechos con manos que crean y mares que inspiran',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withAlpha(204), // Fixed deprecated
                          ),
                    )
                        .animate()
                        .fade(duration: 1500.ms, delay: 1500.ms)
                        .slideY(begin: 0.5, end: 0, duration: 1000.ms, curve: Curves.easeOut),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
