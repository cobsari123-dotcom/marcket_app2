import 'package:flutter/material.dart';
import 'package:marcket_app/providers/feed_provider.dart';
import 'package:marcket_app/widgets/publication_card.dart';
import 'package:marcket_app/widgets/publication_card_skeleton.dart';
import 'package:provider/provider.dart';

class AdminFeedScreen extends StatefulWidget {
  const AdminFeedScreen({super.key});

  @override
  State<AdminFeedScreen> createState() => _AdminFeedScreenState();
}

class _AdminFeedScreenState extends State<AdminFeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // The FeedProvider is likely already initialized by another screen,
    // but we can call init here to be safe if this is the first screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FeedProvider>(context, listen: false).init();
    });

    _scrollController.addListener(() {
      final provider = Provider.of<FeedProvider>(context, listen: false);
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          provider.hasMorePublications &&
          !provider.isLoadingMore) {
        provider.loadMorePublications();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingInitial) {
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: 5,
            itemBuilder: (context, index) => const PublicationCardSkeleton(),
          );
        }

        if (provider.errorMessage != null) {
          return Center(child: Text(provider.errorMessage!));
        }

        if (provider.publications.isEmpty) {
          return const Center(child: Text('No hay publicaciones para mostrar.'));
        }

        return RefreshIndicator(
          onRefresh: () => provider.init(),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            itemCount: provider.publications.length + (provider.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.publications.length) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final publication = provider.publications[index];
              final sellerInfo = provider.sellerData[publication.sellerId];
              return PublicationCard(
                publication: publication,
                sellerName: sellerInfo?.fullName ?? 'Cargando...',
                sellerProfilePicture: sellerInfo?.profilePicture,
                onSellerTap: () {
                  Navigator.pushNamed(
                    context,
                    '/public_seller_profile',
                    arguments: publication.sellerId,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
