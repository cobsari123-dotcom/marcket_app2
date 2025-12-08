import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:marcket_app/models/publication.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FullScreenPublicationView extends StatefulWidget {
  final Publication publication;
  final String sellerName;
  final String? sellerProfilePicture;
  final bool isAdmin;
  final VoidCallback onSellerTap;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;

  const FullScreenPublicationView({
    super.key,
    required this.publication,
    required this.sellerName,
    this.sellerProfilePicture,
    this.isAdmin = false,
    required this.onSellerTap,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onShareTap,
  });

  @override
  State<FullScreenPublicationView> createState() =>
      _FullScreenPublicationViewState();
}

class _FullScreenPublicationViewState extends State<FullScreenPublicationView> {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image Carousel
        PageView.builder(
          itemCount: widget.publication.imageUrls.length,
          itemBuilder: (context, imgIndex) {
            return Image.network(
              widget.publication.imageUrls[imgIndex],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.black,
                child: const Icon(Icons.broken_image,
                    size: 80, color: Colors.white),
              ),
            );
          },
        ),
        // Gradient Overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withAlpha((255 * 0.6).round()),
                Colors.transparent,
                Colors.black.withAlpha((255 * 0.8).round())
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.4, 0.7],
            ),
          ),
        ),
        // UI Elements
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSellerInfo(),
              _buildContentAndActions(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSellerInfo() {
    return GestureDetector(
      onTap: widget.onSellerTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.sellerProfilePicture != null
                ? NetworkImage(widget.sellerProfilePicture!)
                : null,
            child: widget.sellerProfilePicture == null
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            widget.sellerName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentAndActions() {
    final bool isLiked = _currentUserId != null &&
        widget.publication.likes.containsKey(_currentUserId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Publication Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.publication.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.publication.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Action Buttons
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              icon: isLiked
                  ? FontAwesomeIcons.solidHeart
                  : FontAwesomeIcons.heart,
              label: widget.publication.likeCount.toString(),
              onTap: widget.onLikeTap,
              color: isLiked ? Colors.red : Colors.white,
            ),
            const SizedBox(height: 20),
            _buildActionButton(
              icon: FontAwesomeIcons.commentDots,
              label: widget.publication.comments.length.toString(),
              onTap: widget.onCommentTap,
            ),
            const SizedBox(height: 20),
            _buildActionButton(
              icon: FontAwesomeIcons.shareFromSquare,
              label: 'Compartir',
              onTap: widget.onShareTap,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    // Disable buttons for admin
    bool isActionDisabled = widget.isAdmin;

    return GestureDetector(
      onTap: isActionDisabled ? null : onTap,
      child: Column(
        children: [
          FaIcon(icon, color: isActionDisabled ? Colors.grey : color, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isActionDisabled ? Colors.grey : Colors.white,
              shadows: [Shadow(blurRadius: 1, color: Colors.black)],
            ),
          ),
        ],
      ),
    );
  }
}
