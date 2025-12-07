import 'package:flutter/material.dart';
import 'package:marcket_app/models/product.dart';
import 'package:marcket_app/providers/product_list_provider.dart';
import 'package:marcket_app/screens/seller/product_details_screen.dart';
import 'package:marcket_app/services/product_service.dart'; // Mantener para el delete
import 'package:marcket_app/widgets/product_card.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:provider/provider.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  final ScrollController _scrollController = ScrollController();
  final ProductService _productService = ProductService(); // Para la eliminación directa
  late ProductListProvider _productListProvider;

  @override
  void initState() {
    super.initState();
    _productListProvider = Provider.of<ProductListProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _productListProvider.refreshProducts(); // Cargar productos después del primer frame
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          _productListProvider.hasMoreProducts &&
          !_productListProvider.isLoadingMore) {
        _productListProvider.loadMoreProducts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _showProductMenu(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.visibility, color: AppTheme.primary),
              title: const Text('Ver Producto'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProductDetailsScreen(product: product)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.secondary),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/add_edit_product', arguments: product).then((_) => _productListProvider.refreshProducts());
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.error),
              title: const Text('Eliminar', style: TextStyle(color: AppTheme.error)),
              onTap: () {
                Navigator.pop(context);
                _deleteProduct(context, product);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProduct(BuildContext context, Product product) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar ${product.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar', style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _productService.deleteProduct(product);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Producto eliminado exitosamente!'), backgroundColor: AppTheme.success),
        );
        _productListProvider.refreshProducts(); // Refresh the list
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ocurrió un error al eliminar el producto: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductListProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.errorMessage != null) {
          return Center(child: Text('Error: ${provider.errorMessage}'));
        }
        if (provider.products.isEmpty) {
          return const Center(child: Text('No tienes productos aún.'));
        }
        
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: RefreshIndicator(
              onRefresh: () => provider.refreshProducts(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  int crossAxisCount;
                  double childAspectRatio;
                  if (screenWidth < 600) {
                    crossAxisCount = 2;
                    childAspectRatio = 0.75;
                  } else if (screenWidth < 900) {
                    crossAxisCount = 3;
                    childAspectRatio = 0.8;
                  } else {
                    crossAxisCount = 4;
                    childAspectRatio = 0.9;
                  }

                  return GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      crossAxisSpacing: 12.0,
                      mainAxisSpacing: 12.0,
                    ),
                    itemCount: provider.products.length + (provider.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.products.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final product = provider.products[index];
                      return ProductCard(
                        product: product,
                        onTap: () => _showProductMenu(context, product),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
