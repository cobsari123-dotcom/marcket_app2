// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/utils/theme.dart';

class ComplaintSuggestionScreen extends StatefulWidget {
  const ComplaintSuggestionScreen({super.key});

  @override
  State<ComplaintSuggestionScreen> createState() => _ComplaintSuggestionScreenState();
}

class _ComplaintSuggestionScreenState extends State<ComplaintSuggestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  bool _isAnonymous = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaintSuggestion() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSending = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null && !_isAnonymous) {
        if (mounted) {

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Debes iniciar sesión para enviar una queja/sugerencia no anónima.'), backgroundColor: AppTheme.error),
          );
        }
        setState(() {
          _isSending = false;
        });
        return;
      }

      try {
        final databaseRef = FirebaseDatabase.instance.ref('complaints_suggestions');
        await databaseRef.push().set({
          'userId': _isAnonymous ? 'anonimo' : user?.uid,
          'userEmail': _isAnonymous ? 'anonimo' : user?.email,
          'subject': _subjectController.text,
          'message': _messageController.text,
          'timestamp': ServerValue.timestamp,
          'status': 'pending', // e.g., pending, reviewed, resolved
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Queja/Sugerencia enviada con éxito.'), backgroundColor: AppTheme.success, duration: Duration(seconds: 3)),
          );
          Navigator.pop(context); // Go back after submission
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al enviar: $e'), backgroundColor: AppTheme.error, duration: Duration(seconds: 3)),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buzón de Quejas y Sugerencias'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700), // Limit width for the form
          child: SingleChildScrollView( // Ensure scrolling if content overflows
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Asunto',
                      hintText: 'Breve descripción del tema',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, introduce un asunto.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Mensaje',
                      hintText: 'Describe tu queja o sugerencia',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, introduce tu mensaje.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enviar de forma anónima'),
                    value: _isAnonymous,
                    onChanged: (value) {
                      setState(() {
                        _isAnonymous = value;
                      });
                    },
                    secondary: const Icon(Icons.privacy_tip_outlined, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isSending ? null : _submitComplaintSuggestion,
                    icon: _isSending ? const SizedBox.shrink() : const Icon(Icons.send),
                    label: _isSending ? const CircularProgressIndicator(color: Colors.white) : const Text('Enviar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
