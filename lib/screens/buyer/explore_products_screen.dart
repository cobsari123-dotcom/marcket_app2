import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:marcket_app/providers/feed_provider.dart'; // Reusing FeedProvider for product fetching
import 'package:marcket_app/widgets/product_card.dart';
import 'package:marcket_app/widgets/shimmer_loading.dart';
import 'package:marcket_app/screens/seller/product_details_screen.dart'; // For navigation to product details
import 'package:marcket_app/screens/buyer/seller_search_screen.dart'; // For search functionality
import 'package:marcket_app/services/cart_service.dart'; // For cart icon
import 'package:marcket_app/models/cart_item.dart'; // For cart item count
import 'package:marcket_app/screens/cart_screen.dart';

class ExploreProductsScreen extends StatefulWidget {
  const ExploreProductsScreen({super.key});

  @override
  State<ExploreProductsScreen> createState() => _ExploreProductsScreenState();
}

class _ExploreProductsScreenState extends State<ExploreProductsScreen> {
  // Dependencies for the filter/sort dialog, similar to old FeedScreen
  final List<String> _categories = [
    'Todas',
    'Artesanía',
    'Comida',
    'Servicios',
    'Otros'
  ];
  final Map<String, String> _sortByOptions = {
    'timestamp': 'Más Recientes',
    'title': 'Título',
    'price': 'Precio', // Added price sort
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clear any existing data and fetch fresh data
      // Only fetch if FeedProvider is not already initialized or its data is outdated
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);
      if (feedProvider.products.isEmpty && !feedProvider.isLoading) {
        feedProvider.clearAndFetchProducts();
      }
    });
  }

  void _showFilterSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Filtrar y Ordenar Productos'),
          content: Consumer<FeedProvider>(
            builder: (context, provider, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Categoría:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: provider.selectedCategory ?? 'Todas',
                    onChanged: (String? newValue) {
                      provider
                          .setCategory(newValue == 'Todas' ? null : newValue);
                    },
                    items: _categories
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('Ordenar por:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: provider.sortBy,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        provider.setSortBy(newValue);
                      }
                    },
                    items: _sortByOptions.entries.map<DropdownMenuItem<String>>(
                        (MapEntry<String, String> entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text('Orden:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Switch(
                        value: provider.descending,
                        onChanged: (bool value) {
                          provider.setDescending(value);
                        },
                        activeThumbColor: Theme.of(context).primaryColor,
                      ),
                      Text(provider.descending ? 'Descendente' : 'Ascendente'),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar Productos'),
        automaticallyImplyLeading: false, // Remove default back button
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SellerSearchScreen(),
                ),
              );
            },
          ),
          StreamBuilder<List<CartItem>>(
            stream: CartService().getCartStream(),
            builder: (context, snapshot) {
              int totalItems = 0;
              if (snapshot.hasData) {
                totalItems = snapshot.data!.fold<int>(
                  0,
                  (sum, item) => sum + item.quantity,
                );
              }
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                  if (totalItems > 0)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$totalItems',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSortDialog,
          ),
        ],
      ),
      body: Consumer<FeedProvider>(
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
                crossAxisCount: 2,
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
      ),
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