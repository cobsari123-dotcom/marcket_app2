import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => AppInitializerState();
}

class AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _retrieveLostData();
  }

  Future<void> _retrieveLostData() async {
    final ImagePicker picker = ImagePicker();
    final LostDataResponse response = await picker.retrieveLostData();
    if (response.isEmpty) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/splash');
      }
      return;
    }
    // Logic for handling lost files can be added here if necessary.
    // For now, we navigate directly to splash.
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/splash');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
