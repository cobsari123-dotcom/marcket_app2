import 'package:flutter/material.dart';
// Removed unused imports:
// import 'package:marcket_app/screens/buyer/buyer_dashboard_screen.dart';
// import 'package:marcket_app/screens/seller/seller_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userType; // 'Buyer' or 'Seller'

  const HomeScreen({
    super.key,
    required this.userType,
  }); // Fixed: use_super_parameters

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Redirect based on user type after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/welcome_dashboard');
    });
  }

  @override
  Widget build(BuildContext context) {
    // This screen will just show a loading indicator while redirecting
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
