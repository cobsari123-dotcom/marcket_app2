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
  
  final List<File> _newImages = [];
  List<String> _existingImageUrls = [];
  final List<String> _imagesToRemove = [];

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

  Future<void> _pickImage() async {
    if (_isPickingImage) return;

    try {
      if (mounted) setState(() => _isPickingImage = true);
      
      final pickedFiles = await ImagePicker().pickMultiImage(imageQuality: 70);
      
      if (mounted) {
        setState(() {
          _newImages.addAll(pickedFiles.map((file) => File(file.path)));
        });
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _saveProduct() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    if (_newImages.isEmpty && _existingImageUrls.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona al menos una imagen para el producto.'),
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
          content: Text('Ocurrió un error al guardar el producto: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (UI build method remains the same)
        final isSmallScreen = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Agregar Producto' : 'Editar Producto'),
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
                          _buildTextField(_nameController, 'Nombre del Producto'),
                          const SizedBox(height: 20.0),
                          _buildTextField(_descriptionController, 'Descripción', maxLines: 3),
                          const SizedBox(height: 20.0),
                          _buildTextField(_priceController, 'Precio', keyboardType: TextInputType.number, prefixText: '\$'),
                          const SizedBox(height: 20.0),
                          _buildTextField(_stockController, 'Stock', keyboardType: TextInputType.number),
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
    // ... (This method remains the same)
        return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Imágenes del Producto', style: Theme.of(context).textTheme.titleMedium),
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
              crossAxisCount = 2; // For very small screens
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0, // Maintain square aspect ratio for images
              ),
              itemCount: _existingImageUrls.length + _newImages.length + 1,
              itemBuilder: (context, index) {
                // The last item is the "Add" button
                if (index == _existingImageUrls.length + _newImages.length) {
                  return _buildAddImageButton();
                }

                // Display existing network images
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

                // Display new local images
                final imageIndex = index - _existingImageUrls.length;
                final imageFile = _newImages[imageIndex];
                return _buildImageTile(
                  Image.file(imageFile, fit: BoxFit.cover),
                  () => setState(() => _newImages.removeAt(imageIndex)),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    // ... (This method remains the same)
        return GestureDetector(
      onTap: _pickImage,
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
              Text('Añadir', style: TextStyle(color: AppTheme.marronClaro), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageTile(Widget image, VoidCallback onRemove) {
    // ... (This method remains the same)
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

  Widget _buildTextField(TextEditingController controller, String label, {int? maxLines, TextInputType? keyboardType, String? prefixText}) {
    // ... (This method remains the same)
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
    // ... (This method remains the same)
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
    // ... (This method remains the same)
        return ElevatedButton.icon(
      onPressed: _isLoading ? null : _saveProduct,
      icon: const Icon(Icons.save),
      label: Text(widget.product == null ? 'Guardar Producto' : 'Actualizar Producto'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }
}
