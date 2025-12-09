import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:marcket_app/providers/feed_provider.dart';
import 'package:marcket_app/widgets/publication_card.dart';
import 'package:marcket_app/widgets/shimmer_loading.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to ensure the provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clear any existing data and fetch fresh data
      Provider.of<FeedProvider>(context, listen: false).clearAndFetchPublications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar'),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
      ),
      body: Consumer<FeedProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.publications.isEmpty) {
            return _buildShimmerLoading();
          }

          if (provider.hasError) {
            return Center(child: Text(provider.errorMessage ?? 'Ocurrió un error'));
          }

          if (provider.publications.isEmpty) {
            return const Center(child: Text('No hay publicaciones disponibles.'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchPublications(forceRefresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: provider.publications.length,
              itemBuilder: (context, index) {
                final publication = provider.publications[index];
                return PublicationCard(publication: publication);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: 5, // Show 5 shimmer cards
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: ShimmerLoading.rectangular(
            height: 300, // Adjust height to match PublicationCard
            width: double.infinity,
          ),
        );
      },
    );
  }
}
