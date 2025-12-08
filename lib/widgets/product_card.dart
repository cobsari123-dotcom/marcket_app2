import 'package:flutter/material.dart';
import 'package:marcket_app/models/product.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:marcket_app/services/cart_service.dart';
import 'package:marcket_app/widgets/quantity_selection_dialog.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:marcket_app/providers/wishlist_provider.dart';
import 'package:provider/provider.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final bool isAdmin;

  const ProductCard(
      {super.key,
      required this.product,
      required this.onTap,
      this.isAdmin = false});

  @override
  State<ProductCard> createState() => ProductCardState();
}

class ProductCardState extends State<ProductCard> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool hasImage = widget.product.imageUrls.isNotEmpty;
    final wishlistProvider = Provider.of<WishlistProvider>(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: 'product-image-${widget.product.id}',
                child: hasImage
                    ? Stack(
                        children: [
                          CarouselSlider(
                            options: CarouselOptions(
                              height: double.infinity,
                              viewportFraction: 1.0,
                              enlargeCenterPage: false,
                              onPageChanged: (index, reason) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                            ),
                            items: widget.product.imageUrls.map((imageUrl) {
                              return Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.broken_image,
                                      size: 60, color: AppTheme.marronClaro);
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                      child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ));
                                },
                              );
                            }).toList(),
                          ),
                          Positioned(
                            bottom: 8.0,
                            left: 0.0,
                            right: 0.0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: widget.product.imageUrls.map((url) {
                                int index =
                                    widget.product.imageUrls.indexOf(url);
                                return Container(
                                  width: 8.0,
                                  height: 8.0,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 2.0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == index
                                        ? AppTheme.primary
                                        : Colors.white,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: Icon(
                                wishlistProvider.isFavorite(widget.product.id)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: AppTheme.error,
                              ),
                              onPressed: () {
                                wishlistProvider
                                    .toggleFavorite(widget.product.id);
                              },
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: Icon(Icons.image_not_supported,
                            size: 60, color: AppTheme.marronClaro)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${widget.product.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton.icon(
                      onPressed: widget.isAdmin
                          ? null
                          : () async {
                              int? selectedQuantity = await showDialog<int>(
                                context: context,
                                builder: (context) => QuantitySelectionDialog(
                                    product: widget.product),
                              );

                              if (selectedQuantity != null &&
                                  selectedQuantity > 0) {
                                try {
                                  await CartService().addToCart(
                                      widget.product, selectedQuantity);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${widget.product.name} añadido al carrito (x$selectedQuantity).'),
                                      backgroundColor: AppTheme.success,
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Error al añadir al carrito: $e'),
                                      backgroundColor: AppTheme.error,
                                    ),
                                  );
                                }
                              }
                            },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Añadir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
