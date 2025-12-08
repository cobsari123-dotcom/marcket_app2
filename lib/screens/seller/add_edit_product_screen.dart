import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marcket_app/models/product.dart';
import 'package:marcket_app/services/product_service.dart';
import 'package:marcket_app/utils/theme.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _categoryController = TextEditingController();
  final _imageUrlController =
      TextEditingController(); // New controller for image URL

  final List<File> _newImages = [];
  List<String> _existingImageUrls = [];
  final List<String> _imagesToRemove = [];
  final List<String> _newImageUrlsFromWeb =
      []; // New list for image URLs from web

  bool _isFeatured = false;
  bool _isLoading = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
      _categoryController.text = widget.product!.category;
      _isFeatured = widget.product!.isFeatured;
      _existingImageUrls = List<String>.from(widget.product!.imageUrls);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose(); // Dispose new controller
    super.dispose();
  }

  Future<void> _pickImage({ImageSource source = ImageSource.gallery}) async {
    if (_isPickingImage) return;

    try {
      if (mounted) setState(() => _isPickingImage = true);

      final pickedFile =
          await ImagePicker().pickImage(source: source, imageQuality: 70);

      if (pickedFile != null && mounted) {
        setState(() {
          _newImages.add(File(pickedFile.path));
        });
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _showImageSourceSelection() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(source: ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(source: ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Desde URL'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddImageUrlDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddImageUrlDialog() async {
    _imageUrlController.clear();
    final urlFormKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Añadir Imagen desde URL'),
          content: Form(
            key: urlFormKey,
            child: TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'URL de la Imagen',
                hintText: 'Ej: https://ejemplo.com/imagen.jpg',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, ingresa una URL.';
                }
                // Basic URL validation
                if (Uri.tryParse(value)?.hasAbsolutePath != true) {
                  return 'Ingresa una URL válida.';
                }
                // Basic image file extension check
                if (!value.toLowerCase().endsWith('.jpg') &&
                    !value.toLowerCase().endsWith('.jpeg') &&
                    !value.toLowerCase().endsWith('.png') &&
                    !value.toLowerCase().endsWith('.gif') &&
                    !value.toLowerCase().endsWith('.webp')) {
                  return 'La URL debe ser de una imagen (jpg, png, gif, webp).';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (urlFormKey.currentState?.validate() ?? false) {
                  setState(() {
                    _newImageUrlsFromWeb.add(_imageUrlController.text.trim());
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveProduct() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_newImages.isEmpty &&
        _existingImageUrls.isEmpty &&
        _newImageUrlsFromWeb.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Por favor, selecciona al menos una imagen para el producto.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      await _productService.saveProduct(
        existingProduct: widget.product,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        stock: int.parse(_stockController.text.trim()),
        category: _categoryController.text.trim(),
        isFeatured: _isFeatured,
        existingImageUrls: _existingImageUrls,
        newImages: _newImages,
        imagesToRemove: _imagesToRemove,
        newImageUrlsFromWeb: _newImageUrlsFromWeb, // Pass new web urls
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Producto guardado exitosamente!'),
          backgroundColor: AppTheme.success,
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Ocurrió un error al guardar el producto: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.product == null ? 'Agregar Producto' : 'Editar Producto'),
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Card(
                  elevation: isSmallScreen ? 0 : 8,
                  color: isSmallScreen ? Colors.transparent : AppTheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _buildImagePicker(),
                          const SizedBox(height: 20.0),
                          _buildTextField(
                              _nameController, 'Nombre del Producto'),
                          const SizedBox(height: 20.0),
                          _buildTextField(_descriptionController, 'Descripción',
                              maxLines: 3),
                          const SizedBox(height: 20.0),
                          _buildTextField(_priceController, 'Precio',
                              keyboardType: TextInputType.number,
                              prefixText: '\$'),
                          const SizedBox(height: 20.0),
                          _buildTextField(_stockController, 'Stock',
                              keyboardType: TextInputType.number),
                          const SizedBox(height: 20.0),
                          _buildTextField(_categoryController, 'Categoría'),
                          const SizedBox(height: 20.0),
                          _buildFeaturedSwitch(),
                          const SizedBox(height: 30.0),
                          _buildSaveButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Imágenes del Producto',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            int crossAxisCount;
            if (screenWidth > 900) {
              crossAxisCount = 5;
            } else if (screenWidth > 600) {
              crossAxisCount = 4;
            } else if (screenWidth > 400) {
              crossAxisCount = 3;
            } else {
              crossAxisCount = 2;
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: _existingImageUrls.length +
                  _newImages.length +
                  _newImageUrlsFromWeb.length +
                  1,
              itemBuilder: (context, index) {
                if (index ==
                    _existingImageUrls.length +
                        _newImages.length +
                        _newImageUrlsFromWeb.length) {
                  return _buildAddImageButton();
                }

                if (index < _existingImageUrls.length) {
                  final imageUrl = _existingImageUrls[index];
                  return _buildImageTile(
                    Image.network(imageUrl, fit: BoxFit.cover),
                    () => setState(() {
                      _existingImageUrls.removeAt(index);
                      _imagesToRemove.add(imageUrl);
                    }),
                  );
                }

                if (index < _existingImageUrls.length + _newImages.length) {
                  final imageIndex = index - _existingImageUrls.length;
                  final imageFile = _newImages[imageIndex];
                  return _buildImageTile(
                    Image.file(imageFile, fit: BoxFit.cover),
                    () => setState(() => _newImages.removeAt(imageIndex)),
                  );
                }

                final imageUrlIndex =
                    index - (_existingImageUrls.length + _newImages.length);
                final imageUrl = _newImageUrlsFromWeb[imageUrlIndex];
                return _buildImageTile(
                  Image.network(imageUrl, fit: BoxFit.cover),
                  () => setState(
                      () => _newImageUrlsFromWeb.removeAt(imageUrlIndex)),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _showImageSourceSelection,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.marronClaro),
          borderRadius: BorderRadius.circular(12.0),
          color: AppTheme.background,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo, size: 40, color: AppTheme.marronClaro),
              SizedBox(height: 4),
              Text('Añadir',
                  style: TextStyle(color: AppTheme.marronClaro),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageTile(Widget image, VoidCallback onRemove) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11.0),
            child: image,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int? maxLines, TextInputType? keyboardType, String? prefixText}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (value) => value!.isEmpty ? 'Por favor ingresa $label' : null,
    );
  }

  Widget _buildFeaturedSwitch() {
    return SwitchListTile(
      title: const Text('¿Producto destacado?'),
      value: _isFeatured,
      onChanged: (value) {
        setState(() {
          _isFeatured = value;
        });
      },
      activeThumbColor: AppTheme.secondary,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _saveProduct,
      icon: const Icon(Icons.save),
      label: Text(
          widget.product == null ? 'Guardar Producto' : 'Actualizar Producto'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }
}
