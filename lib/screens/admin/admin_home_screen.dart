import 'package:flutter/material.dart';
// import 'package:marcket_app/screens/buyer/feed_screen.dart'; // Removed
import 'package:marcket_app/screens/common/welcome_dashboard_screen.dart'; // New import

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenida Administrativa'), // Changed title for Welcome
        automaticallyImplyLeading: false, // Ensure no back button
      ),
      body: const WelcomeDashboardScreen(), // Replaced FeedScreen
    );
  }
}
