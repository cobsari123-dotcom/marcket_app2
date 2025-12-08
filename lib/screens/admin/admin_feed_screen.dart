import 'package:flutter/material.dart';
import 'package:marcket_app/providers/feed_provider.dart';
import 'package:marcket_app/widgets/comment_sheet.dart';
import 'package:marcket_app/widgets/full_screen_publication_view.dart';
import 'package:provider/provider.dart';

class AdminFeedScreen extends StatefulWidget {
  const AdminFeedScreen({super.key});

  @override
  State<AdminFeedScreen> createState() => _AdminFeedScreenState();
}

class _AdminFeedScreenState extends State<AdminFeedScreen> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FeedProvider>(context, listen: false).init();
    });

    _pageController.addListener(() {
      final provider = Provider.of<FeedProvider>(context, listen: false);
      if (_pageController.page != null &&
          _pageController.page! >= provider.publications.length - 2 &&
          provider.hasMorePublications &&
          !provider.isLoadingMore) {
        provider.loadMorePublications();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<FeedProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.white)));
          }

          if (provider.publications.isEmpty) {
            return const Center(child: Text('No hay publicaciones para mostrar.', style: const TextStyle(color: Colors.white)));
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: provider.publications.length + (provider.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.publications.length) {
                return const Center(child: CircularProgressIndicator());
              }
              final publication = provider.publications[index];
              final sellerInfo = provider.sellerData[publication.sellerId];
              
              return FullScreenPublicationView(
                publication: publication,
                sellerName: sellerInfo?.fullName ?? 'Cargando...',
                sellerProfilePicture: sellerInfo?.profilePicture,
                isAdmin: true, // Admins can't like/comment/share
                onSellerTap: () {
                  Navigator.pushNamed(
                    context,
                    '/public_seller_profile',
                    arguments: {
                      'sellerId': publication.sellerId,
                      'isAdmin': true,
                    },
                  );
                },
                onLikeTap: () {
                  provider.toggleLike(publication.id);
                },
                onCommentTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => CommentSheet(publicationId: publication.id),
                  );
                },
                onShareTap: () {
                  // TODO: Implement share functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Compartir próximamente.')),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}