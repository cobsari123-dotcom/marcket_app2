import 'package:flutter/material.dart';
import 'package:marcket_app/screens/buyer/feed_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed de Publicaciones'),
      ),
      body: const FeedScreen(isAdmin: true),
    );
  }
}
