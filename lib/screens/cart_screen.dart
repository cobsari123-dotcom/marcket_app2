import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:marcket_app/models/order.dart';
import 'package:marcket_app/services/cart_service.dart';
import 'package:marcket_app/models/cart_item.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:collection/collection.dart'; // Import for groupBy
import 'package:image_picker/image_picker.dart'; // New import
import 'package:firebase_storage/firebase_storage.dart'; // New import
import 'dart:io'; // New import

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  bool _isProcessing = false;

  String _selectedPaymentMethod = 'Bank Transfer'; // Default payment method
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _colonyController =
      TextEditingController(); // "Colonia"
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  File? _paymentProofImage;
  bool _isUploadingProof = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _streetController.dispose();
    _colonyController.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _checkout(List<CartItem> cartItems) async {
    setState(() {
      _isProcessing = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para comprar.')),
      );
      _resetProcessingState();
      return;
    }

    // --- Input Validation ---
    if (_streetController.text.isEmpty ||
        _colonyController.text.isEmpty ||
        _postalCodeController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _stateController.text.isEmpty ||
        _phoneNumberController.text.isEmpty ||
        _emailController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Por favor, completa todos los campos de dirección y contacto.'),
          backgroundColor: AppTheme.error,
        ),
      );
      _resetProcessingState();
      return;
    }

    if (_selectedPaymentMethod == 'Bank Transfer' &&
        _paymentProofImage == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Por favor, sube el comprobante de pago para Transferencia Bancaria.'),
          backgroundColor: AppTheme.error,
        ),
      );
      _resetProcessingState();
      return;
    }

    String? paymentProofDownloadUrl;
    if (_selectedPaymentMethod == 'Bank Transfer' &&
        _paymentProofImage != null) {
      try {
        setState(() {
          _isUploadingProof = true;
        });
        final storageRef = FirebaseStorage.instance.ref(
            'payment_proofs/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(_paymentProofImage!);
        paymentProofDownloadUrl = await storageRef.getDownloadURL();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir el comprobante de pago: $e')),
        );
        _resetProcessingState();
        return;
      } finally {
        setState(() {
          _isUploadingProof = false;
        });
      }
    }

    final deliveryAddressMap = {
      'street': _streetController.text,
      'colony': _colonyController.text,
      'postalCode': _postalCodeController.text,
      'city': _cityController.text,
      'state': _stateController.text,
    };

    // Group items by seller
    final itemsBySeller = groupBy(cartItems, (CartItem item) => item.sellerId);

    try {
      final ordersRef = FirebaseDatabase.instance.ref('orders');

      for (var entry in itemsBySeller.entries) {
        final sellerId = entry.key;
        final sellerItems = entry.value;
        final totalPrice = sellerItems.fold<double>(
            0, (sum, item) => sum + (item.price * item.quantity));
        final newOrderId = ordersRef.push().key;

        if (newOrderId == null) {
          throw Exception('Failed to create a new order ID.');
        }

        final newOrder = Order(
          id: newOrderId,
          buyerId: user.uid,
          sellerId: sellerId,
          items: sellerItems,
          totalPrice: totalPrice,
          status: _selectedPaymentMethod == 'Bank Transfer'
              ? OrderStatus.pending
              : OrderStatus.preparing,
          createdAt: DateTime.now(),
          paymentReceiptUrl: paymentProofDownloadUrl,
          deliveryAddress: deliveryAddressMap,
          phoneNumber: _phoneNumberController.text,
          email: _emailController.text,
          paymentMethod: _selectedPaymentMethod,
        );

        await ordersRef.child(newOrderId).set(newOrder.toMap());
      }

      // Clear the cart after successful order creation
      await _cartService.clearCart();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Pedido realizado con éxito!'),
          backgroundColor: AppTheme.success,
        ),
      );

      // TODO: Navigate to the 'My Orders' screen
      // Navigator.pushReplacementNamed(context, '/buyer_orders');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear el pedido: $e')),
      );
    } finally {
      _resetProcessingState();
    }
  }

  void _resetProcessingState() {
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _isUploadingProof = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: 800), // Max width for cart content
          child: StreamBuilder<List<CartItem>>(
            stream: _cartService.getCartStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart_outlined,
                          size: 80, color: AppTheme.primary),
                      const SizedBox(height: 20),
                      Text(
                        'Tu carrito está vacío.',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '¡Explora productos y añade algunos!',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              final cartItems = snapshot.data!;
              double total = cartItems.fold(
                  0, (sum, item) => sum + (item.price * item.quantity));

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: item.imageUrl.isNotEmpty
                                      ? Image.network(item.imageUrl,
                                          fit: BoxFit.cover)
                                      : const Icon(Icons.image_not_supported),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      Text('\$${item.price.toStringAsFixed(2)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge),
                                      // TODO: Fetch and display seller name instead of ID
                                      Text(
                                          'Vendedor: ${item.sellerId.substring(0, 6)}...',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () {
                                        if (item.quantity > 1) {
                                          _cartService.updateCartItemQuantity(
                                              item.productId,
                                              item.quantity - 1);
                                        } else {
                                          _cartService
                                              .removeFromCart(item.productId);
                                        }
                                      },
                                    ),
                                    Text('${item.quantity}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () {
                                        _cartService.updateCartItemQuantity(
                                            item.productId, item.quantity + 1);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: AppTheme.error),
                                      onPressed: () {
                                        _cartService
                                            .removeFromCart(item.productId);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildPaymentAndDeliverySection(), // NEW: Payment method selection and delivery details
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total:',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            Text('\$${total.toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(color: AppTheme.primary)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: (cartItems.isEmpty || _isProcessing)
                                ? null
                                : () => _checkout(cartItems),
                            icon: _isProcessing
                                ? const SizedBox.shrink()
                                : const Icon(Icons.check_circle_outline),
                            label: _isProcessing
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text('Finalizar Compra'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              textStyle: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentAndDeliverySection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Método de Pago',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedPaymentMethod,
            items: <String>['Bank Transfer', 'Cash on Delivery']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value == 'Bank Transfer'
                    ? 'Transferencia Bancaria'
                    : 'Pago contra Entrega'),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedPaymentMethod = newValue!;
              });
            },
            decoration: const InputDecoration(
              labelText: 'Selecciona método de pago',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          if (_selectedPaymentMethod == 'Bank Transfer') ...[
            Text(
              'Datos de Transferencia Bancaria',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Banco: Ejemplo Bank',
                        style: Theme.of(context).textTheme.bodyLarge),
                    Text('Número de Cuenta: 1234567890',
                        style: Theme.of(context).textTheme.bodyLarge),
                    Text('CLABE: 012345678901234567',
                        style: Theme.of(context).textTheme.bodyLarge),
                    Text('Beneficiario: Nombre del Beneficiario',
                        style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Comprobante de Pago',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _paymentProofImage == null
                ? OutlinedButton.icon(
                    onPressed: _pickPaymentProof,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Subir Comprobante'),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.file(_paymentProofImage!, height: 150),
                      TextButton.icon(
                        onPressed: _pickPaymentProof,
                        icon: const Icon(Icons.edit),
                        label: const Text('Cambiar Comprobante'),
                      ),
                    ],
                  ),
            if (_isUploadingProof) const LinearProgressIndicator(),
            const SizedBox(height: 24),
          ],
          Text(
            'Dirección de Entrega y Contacto',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _streetController,
            decoration: const InputDecoration(
              labelText: 'Calle y Número',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.home),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, ingresa la calle y número.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _colonyController,
            decoration: const InputDecoration(
              labelText: 'Colonia/Pueblo/Carretera',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_city),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, ingresa la colonia o pueblo.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _postalCodeController,
            decoration: const InputDecoration(
              labelText: 'Código Postal',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.local_post_office),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, ingresa el código postal.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: 'Ciudad',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.apartment),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, ingresa la ciudad.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _stateController,
            decoration: const InputDecoration(
              labelText: 'Estado',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.map),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, ingresa el estado.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneNumberController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Número de Teléfono',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, ingresa tu número de teléfono.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo Electrónico',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, ingresa tu correo electrónico.';
              }
              if (!value.contains('@')) {
                return 'Por favor, ingresa un correo electrónico válido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _pickPaymentProof() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _paymentProofImage = File(pickedFile.path);
      });
    }
  }
}
