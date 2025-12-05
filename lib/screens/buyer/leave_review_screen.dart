import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/review.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/utils/theme.dart';

class LeaveReviewScreen extends StatefulWidget {
  final String productId;
  final String orderId;
  final String sellerId;

  const LeaveReviewScreen({
    super.key,
    required this.productId,
    required this.orderId,
    required this.sellerId,
  });

  @override
  State<LeaveReviewScreen> createState() => LeaveReviewScreenState();
}

class LeaveReviewScreenState extends State<LeaveReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _rating = 3.0;
  bool _isSubmitting = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userSnapshot = await FirebaseDatabase.instance.ref('users/${user.uid}').get();
    if (userSnapshot.exists) {
      if (!mounted) return;
      setState(() {
        _currentUser = UserModel.fromMap(Map<String, dynamic>.from(userSnapshot.value as Map), user.uid);
      });
    }
  }

  Future<void> _submitReview() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isSubmitting || _currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      final reviewsRef = FirebaseDatabase.instance.ref('reviews/${widget.productId}');
      final newReviewRef = reviewsRef.push();

      final review = Review(
        id: newReviewRef.key!,
        productId: widget.productId,
        sellerId: widget.sellerId,
        buyerId: _currentUser!.id,
        buyerName: _currentUser!.fullName,
        rating: _rating,
        comment: _commentController.text.trim(),
        timestamp: DateTime.now(),
      );

      await newReviewRef.set(review.toMap());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Gracias por tu reseña!'), backgroundColor: AppTheme.success),
      );
      if (!mounted) return;
      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar la reseña: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dejar una Reseña'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), // Limit width for the form
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '¿Qué te pareció el producto?',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: RatingBar.builder(
                      initialRating: _rating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate: (rating) {
                        setState(() {
                          _rating = rating;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Tu comentario',
                      hintText: 'Describe tu experiencia con el producto...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, escribe un comentario.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitReview,
                    icon: _isSubmitting ? const SizedBox.shrink() : const Icon(Icons.send),
                    label: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Publicar Reseña'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
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
