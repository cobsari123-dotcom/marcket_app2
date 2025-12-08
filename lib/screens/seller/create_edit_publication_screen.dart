import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:marcket_app/models/publication.dart';
import 'package:marcket_app/utils/theme.dart';

class CreateEditPublicationScreen extends StatefulWidget {
  final Publication? publication;

  const CreateEditPublicationScreen({super.key, this.publication});

  @override
  State<CreateEditPublicationScreen> createState() =>
      _CreateEditPublicationScreenState();
}

class _CreateEditPublicationScreenState
    extends State<CreateEditPublicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _imageUrlController =
      TextEditingController(); // New controller for image URL

  final List<File> _newImages = [];
  List<String> _existingImageUrls = [];
  final List<String> _imagesToRemove = [];
  final List<String> _newImageUrlsFromWeb =
      []; // New list for image URLs from web

  bool _isLoading = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.publication != null) {
      _titleController.text = widget.publication!.title;
      _contentController.text = widget.publication!.content;
      _existingImageUrls = List<String>.from(widget.publication!.imageUrls);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose(); // Dispose new controller
    super.dispose();
  }

  Future<void> _pickImage(
      {ImageSource source = ImageSource.gallery,
      bool multiImage = false}) async {
    if (_isPickingImage) return;

    try {
      if (mounted) setState(() => _isPickingImage = true);

      List<XFile> pickedFiles = [];
      if (multiImage) {
        pickedFiles = await ImagePicker().pickMultiImage(imageQuality: 70);
      } else {
        final pickedFile =
            await ImagePicker().pickImage(source: source, imageQuality: 70);
        if (pickedFile != null) {
          pickedFiles = [pickedFile];
        }
      }

      if (mounted && pickedFiles.isNotEmpty) {
        setState(() {
          _newImages.addAll(pickedFiles.map((file) => File(file.path)));
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
                  _pickImage(source: ImageSource.gallery, multiImage: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(source: ImageSource.camera, multiImage: false);
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

  Future<void> _savePublication() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_newImages.isEmpty &&
        _existingImageUrls.isEmpty &&
        _newImageUrlsFromWeb.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona al menos una imagen.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      List<String> newImageUrls = [];
      for (final imageFile in _newImages) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('publication_images')
            .child(
                '${FirebaseAuth.instance.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}_${newImageUrls.length}.jpg');

        final Uint8List imageData = await imageFile.readAsBytes();
        final metadata = SettableMetadata(contentType: "image/jpeg");
        await storageRef.putData(imageData, metadata);

        final url = await storageRef.getDownloadURL();
        newImageUrls.add(url);
      }

      for (final urlToRemove in _imagesToRemove) {
        try {
          await FirebaseStorage.instance.refFromURL(urlToRemove).delete();
        } catch (e) {
          // It's okay if deletion fails
        }
      }

      final finalImageUrls = [
        ..._existingImageUrls,
        ..._newImageUrlsFromWeb,
        ...newImageUrls
      ];

      final publicationData = {
        'sellerId': FirebaseAuth.instance.currentUser!.uid,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'imageUrls': finalImageUrls,
        'timestamp': widget.publication?.timestamp.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
        'modifiedTimestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final publicationsRef = FirebaseDatabase.instance.ref('publications');
      if (widget.publication != null) {
        await publicationsRef
            .child(widget.publication!.id)
            .update(publicationData);
      } else {
        publicationData['ratings'] = {};
        await publicationsRef.push().set(publicationData);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Publicación guardada exitosamente!'),
          backgroundColor: AppTheme.success,
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocurrió un error al guardar: ${e.toString()}'),
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
        title: Text(widget.publication == null
            ? 'Crear Publicación'
            : 'Editar Publicación'),
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
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
                              _titleController, 'Título de la Publicación'),
                          const SizedBox(height: 20.0),
                          _buildTextField(
                              _contentController, 'Contenido de la historia',
                              maxLines: 10),
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
        Text('Imágenes', style: Theme.of(context).textTheme.titleMedium),
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
                childAspectRatio:
                    1.0, // Maintain square aspect ratio for images
              ),
              itemCount: _existingImageUrls.length +
                  _newImages.length +
                  _newImageUrlsFromWeb.length +
                  1,
              itemBuilder: (context, index) {
                // The last item is the "Add" button
                if (index ==
                    _existingImageUrls.length +
                        _newImages.length +
                        _newImageUrlsFromWeb.length) {
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
                if (index < _existingImageUrls.length + _newImages.length) {
                  final imageIndex = index - _existingImageUrls.length;
                  final imageFile = _newImages[imageIndex];
                  return _buildImageTile(
                    Image.file(imageFile, fit: BoxFit.cover),
                    () => setState(() => _newImages.removeAt(imageIndex)),
                  );
                }

                // Display new URL images
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
      {int? maxLines}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
      ),
      maxLines: maxLines,
      validator: (value) => value!.isEmpty ? 'Por favor ingresa $label' : null,
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _savePublication,
      icon: const Icon(Icons.save),
      label: Text(widget.publication == null ? 'Publicar' : 'Actualizar'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }
}
