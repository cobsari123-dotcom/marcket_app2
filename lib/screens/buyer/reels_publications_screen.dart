import 'package:flutter/material.dart';
import 'package:marcket_app/models/publication.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/services/publication_service.dart';
import 'package:marcket_app/services/user_service.dart';
import 'package:marcket_app/widgets/full_screen_publication_view.dart';
import 'package:marcket_app/widgets/comment_sheet.dart'; // Import for comment sheet
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart'; // Import for sharing

class ReelsPublicationsScreen extends StatefulWidget {
  const ReelsPublicationsScreen({super.key});

  @override
  State<ReelsPublicationsScreen> createState() => _ReelsPublicationsScreenState();
}

class _ReelsPublicationsScreenState extends State<ReelsPublicationsScreen> {
  final PublicationService _publicationService = PublicationService();
  final UserService _userService = UserService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  List<Publication> _publications = [];
  final Map<String, UserModel> _sellerData = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPublications();
  }

  Future<void> _fetchPublications() async {
    try {
      final result = await _publicationService.getPublications(
        limit: 20, // Fetch a reasonable number of publications initially
        // You might want to add pagination or a continuous scroll later
      );
      final List<Publication> fetchedPublications = result['publications'];

      await _fetchSellerDataForPublications(fetchedPublications);

      if (mounted) {
        setState(() {
          _publications = fetchedPublications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar publicaciones: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchSellerDataForPublications(List<Publication> publications) async {
    final Set<String> sellerIds = publications.map((p) => p.sellerId).toSet();
    for (final id in sellerIds) {
      if (!_sellerData.containsKey(id)) {
        final seller = await _userService.getUserById(id);
        if (seller != null) {
          _sellerData[id] = seller;
        }
      }
    }
  }

  void _handleLike(Publication publication) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Necesitas iniciar sesión para dar "me gusta".')),
      );
      return;
    }

    final pubIndex = _publications.indexWhere((p) => p.id == publication.id);
    if (pubIndex == -1) return;

    final bool isLiked = publication.likes.containsKey(_currentUserId);

    // Optimistic update
    setState(() {
      if (isLiked) {
        _publications[pubIndex].likes.remove(_currentUserId);
        _publications[pubIndex].likes[_currentUserId] = true;
      }
    });

    try {
      await _publicationService.toggleLike(publication.id);
    } catch (e) {
      // Revert on error
      setState(() {
        if (isLiked) {
          _publications[pubIndex].likes[_currentUserId] = true;
        } else {
          _publications[pubIndex].likes.remove(_currentUserId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al actualizar el 'me gusta': $e")),
      );
    }
  }

  void _handleComment(Publication publication) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return CommentSheet(
          publicationId: publication.id,
        );
      },
    );
  }

  void _handleShare(Publication publication) {
    Share.share('¡Mira esta publicación en Manos del Mar!\n${publication.title}\n${publication.imageUrls.first}');
  }

  void _handleSellerTap(String sellerId) {
    Navigator.pushNamed(context, '/public_seller_profile', arguments: {'sellerId': sellerId});
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Publicaciones (Reels)')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    if (_publications.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Publicaciones (Reels)')),
        body: const Center(child: Text('No hay publicaciones disponibles.')),
      );
    }

    return Scaffold(
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: _publications.length,
        itemBuilder: (context, index) {
          final publication = _publications[index];
          final seller = _sellerData[publication.sellerId];
          return FullScreenPublicationView(
            publication: publication,
            sellerName: seller?.fullName ?? 'Desconocido',
            sellerProfilePicture: seller?.profilePicture,
            onLikeTap: () => _handleLike(publication),
            onCommentTap: () => _handleComment(publication),
            onShareTap: () => _handleShare(publication),
            onSellerTap: () => _handleSellerTap(publication.sellerId),
          );
        },
      ),
    );
  }
}
