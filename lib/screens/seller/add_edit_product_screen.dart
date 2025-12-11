import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marcket_app/models/product.dart';
import 'package:marcket_app/services/product_service.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:intl/intl.dart'; // Import for DateFormat

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
  final _imageUrlController = TextEditingController();

  // New controllers for freshness and weight
  final _freshnessController = TextEditingController();
  final _freshnessDateController = TextEditingController();
  final _weightValueController = TextEditingController();
  final _weightUnitController = TextEditingController();

  String _selectedProductType = 'Artesanía'; // Default product type

  final List<File> _newImages = [];
  List<String> _existingImageUrls = [];
  final List<String> _imagesToRemove = [];
  final List<String> _newImageUrlsFromWeb = [];

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

      // Initialize new fields
      _freshnessController.text = widget.product!.freshness ?? '';
      if (widget.product!.freshnessDate != null) {
        _freshnessDateController.text = DateFormat('dd/MM/yyyy').format(widget.product!.freshnessDate!);
      }
      _weightValueController.text = widget.product!.weightValue?.toString() ?? '';
      _weightUnitController.text = widget.product!.weightUnit ?? '';
      _selectedProductType = widget.product!.productType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    // Dispose new controllers
    _freshnessController.dispose();
    _freshnessDateController.dispose();
    _weightValueController.dispose();
    _weightUnitController.dispose();
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
                if (Uri.tryParse(value)?.hasAbsolutePath != true) {
                  return 'Ingresa una URL válida.';
                }
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

  Future<void> _selectFreshnessDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      if (!mounted) return;
      setState(() {
        _freshnessDateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      DateTime? parsedFreshnessDate;
      if (_freshnessDateController.text.isNotEmpty) {
        try {
          parsedFreshnessDate = DateFormat('dd/MM/yyyy').parse(_freshnessDateController.text);
        } catch (e) {
          debugPrint('Error parsing freshness date: $e');
        }
      }

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
        newImageUrlsFromWeb: _newImageUrlsFromWeb,
        // New fields
        productType: _selectedProductType,
        freshness: _selectedProductType == 'Marisco' && _freshnessController.text.trim().isNotEmpty
            ? _freshnessController.text.trim()
            : null,
        freshnessDate: _selectedProductType == 'Marisco' ? parsedFreshnessDate : null,
        weightValue: _selectedProductType == 'Marisco' && _weightValueController.text.trim().isNotEmpty
            ? double.tryParse(_weightValueController.text.trim())
            : null,
        weightUnit: _selectedProductType == 'Marisco' && _weightUnitController.text.trim().isNotEmpty
            ? _weightUnitController.text.trim()
            : null,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
                          _buildProductTypeSelector(), // New product type selector
                          if (_selectedProductType == 'Marisco') ...[
                            const SizedBox(height: 20.0),
                            _buildTextField(
                                _freshnessController, 'Frescura (ej. Fresco del mar, 2 días)'),
                            const SizedBox(height: 20.0),
                            TextFormField(
                              controller: _freshnessDateController,
                              decoration: const InputDecoration(
                                labelText: 'Fecha de Frescura (opcional)',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              onTap: () => _selectFreshnessDate(context),
                            ),
                            const SizedBox(height: 20.0),
                            _buildTextField(
                                _weightValueController, 'Cantidad/Peso',
                                keyboardType: TextInputType.number),
                            const SizedBox(height: 20.0),
                            _buildTextField(
                                _weightUnitController, 'Unidad (ej. kg, g, unidad)'),
                          ],
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

  Widget _buildProductTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipo de Producto', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const <ButtonSegment<String>>[
            ButtonSegment<String>(value: 'Artesanía', label: Text('Artesanía')),
            ButtonSegment<String>(value: 'Marisco', label: Text('Marisco')),
          ],
          selected: <String>{_selectedProductType},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              _selectedProductType = newSelection.first;
            });
          },
          emptySelectionAllowed: false,
          multiSelectionEnabled: false,
        ),
      ],
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          if (label == 'Fecha de Frescura (opcional)') {
            return null; // Date is optional
          }
          if (_selectedProductType == 'Marisco' &&
              (label == 'Frescura (ej. Fresco del mar, 2 días)' ||
                  label == 'Cantidad/Peso' ||
                  label == 'Unidad (ej. kg, g, unidad)')) {
            return 'Por favor ingresa $label';
          }
          return 'Por favor ingresa $label';
        }
        return null;
      },
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
