import 'package:flutter/material.dart';
import 'package:marcket_app/providers/feed_provider.dart';
import 'package:marcket_app/widgets/publication_card.dart';
import 'package:marcket_app/widgets/publication_card_skeleton.dart';
import 'package:provider/provider.dart';
import 'package:marcket_app/utils/theme.dart'; // Importar AppTheme para colores

class FeedScreen extends StatefulWidget {
  final bool isAdmin;
  const FeedScreen({super.key, this.isAdmin = false});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  late FeedProvider _feedProvider;

  // Opciones de categorías (ejemplo, estas podrían venir de un servicio)
  final List<String> _categories = ['Todas', 'Artesanía', 'Comida', 'Servicios', 'Otros'];

  // Opciones de ordenamiento
  final Map<String, String> _sortByOptions = {
    'timestamp': 'Más Recientes',
    'title': 'Título',
    // 'price': 'Precio', // Necesitaría que Publication tuviera un campo price para esto
  };

  @override
  void initState() {
    super.initState();
    _feedProvider = Provider.of<FeedProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _feedProvider.init(); // Llamar al método init del provider después del primer frame
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          _feedProvider.hasMorePublications &&
          !_feedProvider.isLoadingMore) {
        _feedProvider.loadMorePublications();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showFilterSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Filtrar y Ordenar Publicaciones'),
          content: Consumer<FeedProvider>(
            builder: (context, provider, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Categoría:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: provider.selectedCategory ?? 'Todas',
                    onChanged: (String? newValue) {
                      provider.setCategory(newValue == 'Todas' ? null : newValue);
                    },
                    items: _categories.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('Ordenar por:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: provider.sortBy,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        provider.setSortBy(newValue);
                      }
                    },
                    items: _sortByOptions.entries.map<DropdownMenuItem<String>>((MapEntry<String, String> entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text('Orden:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Switch(
                        value: provider.descending,
                        onChanged: (bool value) {
                          provider.setDescending(value);
                        },
                        activeThumbColor: AppTheme.primary,
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
      body: Consumer<FeedProvider>(
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
                  isAdmin: widget.isAdmin, // Pass the flag here
                  onSellerTap: () {
                    Navigator.pushNamed(
                      context,
                      '/public_seller_profile',
                      arguments: {
                        'sellerId': publication.sellerId,
                        'isAdmin': widget.isAdmin,
                      },
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFilterSortDialog(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.filter_list),
      ),
    );
  }
}