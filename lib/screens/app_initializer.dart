import 'package:flutter/foundation.dart';
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
    _initialize();
  }

  Future<void> _initialize() async {
    // retrieveLostData is not supported on web, so we bypass it.
    if (!kIsWeb) {
      final ImagePicker picker = ImagePicker();
      final LostDataResponse response = await picker.retrieveLostData();
      if (!response.isEmpty) {
        // Logic for handling lost files can be added here if necessary.
      }
    }
    
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