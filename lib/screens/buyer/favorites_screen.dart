import 'package:flutter/material.dart';
import 'package:marcket_app/models/product.dart';
import 'package:marcket_app/providers/wishlist_provider.dart';
import 'package:marcket_app/services/product_service.dart';
import 'package:marcket_app/widgets/product_card.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, child) {
        if (wishlistProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (wishlistProvider.wishlistProductIds.isEmpty) {
          return const Center(
            child: Text('Aún no tienes productos favoritos.'),
          );
        }

        return FutureBuilder<List<Product>>(
          future: _getFavoriteProducts(wishlistProvider.wishlistProductIds),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No se pudieron cargar los productos favoritos.'),
              );
            }

            final products = snapshot.data!;

            return LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                int crossAxisCount;
                if (screenWidth > 1200) {
                  crossAxisCount = 5;
                } else if (screenWidth > 900) {
                  crossAxisCount = 4;
                } else if (screenWidth > 600) {
                  crossAxisCount = 3;
                } else {
                  crossAxisCount = 2;
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductCard(
                      product: product,
                      onTap: () {
                        // Navegar a la pantalla de detalle del producto
                        // Navigator.push...
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<Product>> _getFavoriteProducts(List<String> productIds) async {
    final productService = ProductService();
    List<Product> products = [];
    for (String id in productIds) {
      final product = await productService.getProductById(id);
      if (product != null) {
        products.add(product);
      }
    }
    return products;
  }
}
