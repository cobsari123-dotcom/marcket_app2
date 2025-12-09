import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:marcket_app/providers/feed_provider.dart';
import 'package:marcket_app/widgets/product_card.dart';
import 'package:marcket_app/widgets/shimmer_loading.dart';
import 'package:marcket_app/screens/seller/product_details_screen.dart'; // Needed for onTap navigation

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
      Provider.of<FeedProvider>(context, listen: false).clearAndFetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.products.isEmpty) {
            return _buildShimmerLoading();
          }

          if (provider.hasError) {
            return Center(child: Text(provider.errorMessage ?? 'Ocurrió un error'));
          }

          if (provider.products.isEmpty) {
            return const Center(child: Text('No hay productos disponibles.'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchProducts(forceRefresh: true),
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Adjust as needed
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.7,
              ),
              itemCount: provider.products.length,
              itemBuilder: (context, index) {
                final product = provider.products[index];
                final seller = provider.sellerData[product.sellerId];
                return ProductCard(
                  product: product,
                  sellerName: seller?.fullName,
                  sellerProfilePicture: seller?.profilePicture,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsScreen(product: product),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
    );
  }

  Widget _buildShimmerLoading() {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 0.7,
      ),
      itemCount: 6, // Show 6 shimmer cards for a 2-column grid
      itemBuilder: (context, index) {
        return const ShimmerLoading.rectangular(
          height: 300,
          width: double.infinity,
        );
      },
    );
  }
}
