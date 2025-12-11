// ignore_for_file: prefer_const_constructors
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marcket_app/models/order.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/screens/buyer/leave_review_screen.dart';
import 'package:marcket_app/screens/full_screen_image_viewer.dart';
import 'package:marcket_app/screens/common/contact_support_screen.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => OrderDetailScreenState();
}

class OrderDetailScreenState extends State<OrderDetailScreen> {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  UserModel? _currentUser;
  UserModel? _seller;
  Stream<DatabaseEvent>? _orderStream;
  bool _isProcessing = false;
  
  final TextEditingController _rejectionReasonController = TextEditingController();
  final TextEditingController _trackingNumberController = TextEditingController();
  final TextEditingController _estimatedDeliveryDateController = TextEditingController();
  DateTime? _selectedEstimatedDeliveryDate;
  final TextEditingController _estimatedDeliveryTimeWindowController = TextEditingController();
  final TextEditingController _deliveryCodeConfirmationController = TextEditingController();

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    _trackingNumberController.dispose();
    _estimatedDeliveryDateController.dispose();
    _estimatedDeliveryTimeWindowController.dispose();
    _deliveryCodeConfirmationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _orderStream = FirebaseDatabase.instance.ref('orders/${widget.orderId}').onValue;
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    if (_currentUserId == null) {
      return;
    }
    final userSnapshot = await FirebaseDatabase.instance.ref('users/$_currentUserId').get();
    if (userSnapshot.exists && mounted) {
      setState(() {
        _currentUser = UserModel.fromMap(
            Map<String, dynamic>.from(userSnapshot.value as Map),
            _currentUserId);
      });
    }
  }

  Future<void> _loadSellerData(String sellerId) async {
    if (_seller != null) {
      return;
    }
    final sellerSnapshot = await FirebaseDatabase.instance.ref('users/$sellerId').get();
    if (sellerSnapshot.exists && mounted) {
      setState(() {
        _seller = UserModel.fromMap(
            Map<String, dynamic>.from(sellerSnapshot.value as Map), sellerId);
      });
    }
  }

  String _generateDeliveryCode() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<void> _uploadReceipt(Order order) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null || !mounted) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final file = File(pickedFile.path);
      final Uint8List imageData = await file.readAsBytes();
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('payment_receipts')
          .child(order.id)
          .child('receipt.jpg');

      final metadata = SettableMetadata(contentType: "image/jpeg");
      await storageRef.putData(imageData, metadata);
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseDatabase.instance.ref('orders/${order.id}').update({
        'paymentReceiptUrl': downloadUrl,
        'status': OrderStatus.verifying.toString().split('.').last,
      });

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Comprobante subido con éxito.'),
            backgroundColor: AppTheme.success),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al subir el comprobante: $e'),
            backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handlePaymentVerification(Order order, bool isConfirmed,
      {String? rejectionReason}) async {
    setState(() => _isProcessing = true);

    try {
      if (isConfirmed) {
        String? generatedDeliveryCode;
        if (order.deliveryCode == null) {
          // Only generate if not already present
          generatedDeliveryCode = _generateDeliveryCode();
        }

        Map<String, dynamic> updates = {
          'status': OrderStatus.preparing.toString().split('.').last,
        };
        if (generatedDeliveryCode != null) {
          updates['deliveryCode'] = generatedDeliveryCode;
        }

        await FirebaseDatabase.instance
            .ref('orders/${order.id}')
            .update(updates);

        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pago confirmado. Prepara el pedido.'),
              backgroundColor: AppTheme.success),
        );
      } else {
        await FirebaseDatabase.instance.ref('orders/${order.id}').update({
          'status': OrderStatus.pending
              .toString()
              .split('.')
              .last, // Revert to pending for re-upload
          'paymentReceiptUrl': null, // Clear the uploaded receipt
          'rejectionReason': rejectionReason,
          'deliveryCode': null, // Clear delivery code on rejection
        });

        if (order.paymentReceiptUrl != null &&
            order.paymentReceiptUrl!.isNotEmpty) {
          try {
            // Delete old receipt from storage
            await FirebaseStorage.instance
                .refFromURL(order.paymentReceiptUrl!)
                .delete();
          } catch (e) {
            debugPrint('Error deleting old receipt: $e');
            // Ignore if deletion fails, continue with status update
          }
        }
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pago rechazado. Se ha notificado al comprador.'),
              backgroundColor: AppTheme.error),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al verificar el pago: $e'),
            backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _updateOrderStatus(Order order, OrderStatus newStatus,
      {String? trackingNumber,
      DateTime? estimatedDeliveryDate,
      String? deliveryTimeWindow,
      String? rejectionReason,
      bool clearDeliveryCode = false}) async {
    setState(() => _isProcessing = true);

    try {
      Map<String, dynamic> updates = {
        'status': newStatus.toString().split('.').last,
      };
      if (trackingNumber != null) {
        updates['trackingNumber'] = trackingNumber;
      }
      if (estimatedDeliveryDate != null) {
        updates['estimatedDeliveryDate'] =
            estimatedDeliveryDate.millisecondsSinceEpoch;
      }
      if (deliveryTimeWindow != null) {
        updates['deliveryTimeWindow'] = deliveryTimeWindow;
      }
      if (rejectionReason != null) {
        // For cancellation reason
        updates['rejectionReason'] = rejectionReason;
      }
      if (clearDeliveryCode) {
        updates['deliveryCode'] = null;
        updates['trackingNumber'] = null;
        updates['estimatedDeliveryDate'] = null;
        updates['deliveryTimeWindow'] = null;
      }

      await FirebaseDatabase.instance.ref('orders/${order.id}').update(updates);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Estado del pedido actualizado a ${newStatus.toString().split('.').last}.'),
            backgroundColor: AppTheme.success),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al actualizar el estado: $e'),
            backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle del Pedido #${widget.orderId.substring(0, 6)}...'),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _orderStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _currentUser == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.snapshot.exists) {
            return const Center(child: Text('Pedido no encontrado.'));
          }

          final order = Order.fromMap(
              Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map),
              widget.orderId);

          if (_currentUser?.id == order.buyerId) {
            _loadSellerData(order.sellerId);
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                  maxWidth: 800), // Limit width for order details
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Resumen del Pedido'),
                    _buildInfoCard(order),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Información de Entrega'),
                    _buildDeliveryInfoCard(order),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Artículos'),
                    ...order.items.map((item) => _buildItemCard(item)),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Acciones'),
                    _buildActionCard(order),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow('ID Pedido:', '#${order.id.substring(0, 6)}...'),
            _buildInfoRow('Fecha:',
                DateFormat('dd/MM/yyyy, hh:mm a').format(order.createdAt)),
            _buildInfoRow('Total:', '\$${order.totalPrice.toStringAsFixed(2)}',
                isTotal: true),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estado:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                _buildStatusChip(order.status),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfoCard(Order order) {
    if (order.deliveryAddress == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No se proporcionó información de entrega.',
              style: TextStyle(fontStyle: FontStyle.italic)),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Método de Pago:', order.paymentMethod),
            const Divider(height: 20),
            Text('Dirección:',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            _buildInfoRow(
                'Calle y Número:', order.deliveryAddress!['street'] ?? 'N/A'),
            _buildInfoRow(
                'Colonia/Pueblo:', order.deliveryAddress!['colony'] ?? 'N/A'),
            _buildInfoRow('Código Postal:',
                order.deliveryAddress!['postalCode'] ?? 'N/A'),
            _buildInfoRow('Ciudad:', order.deliveryAddress!['city'] ?? 'N/A'),
            _buildInfoRow('Estado:', order.deliveryAddress!['state'] ?? 'N/A'),
            const Divider(height: 20),
            Text('Contacto:',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            _buildInfoRow('Teléfono:', order.phoneNumber ?? 'N/A'),
            _buildInfoRow('Correo:', order.email ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            value,
            style: isTotal
                ? const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.primary)
                : const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(dynamic item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: SizedBox(
          width: 50,
          height: 50,
          child: item.imageUrl.isNotEmpty
              ? Image.network(item.imageUrl, fit: BoxFit.cover)
              : const Icon(Icons.image),
        ),
        title: Text(item.name),
        subtitle: Text('Cantidad: ${item.quantity}'),
        trailing: Text('\$${(item.price * item.quantity).toStringAsFixed(2)}'),
      ),
    );
  }

  Widget _buildActionCard(Order order) {
    bool isBuyer = _currentUser?.id == order.buyerId;

    if (isBuyer) {
      // Vista del Comprador
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En listas de widgets, usamos "Collection If" (sin llaves {})
          if (order.paymentMethod == 'Bank Transfer' &&
              order.status == OrderStatus.pending)
            _buildUploadReceiptAction(order),

          if (order.status == OrderStatus.verifying)
            Text('El vendedor está verificando tu pago.',
                style: Theme.of(context).textTheme.bodyLarge),

          if (order.status == OrderStatus.preparing)
            Text('Tu pedido está siendo preparado por el vendedor.',
                style: Theme.of(context).textTheme.bodyLarge),

          if (order.status == OrderStatus.shipped)
            _buildBuyerTrackingInfo(order),

          if (order.status == OrderStatus.delivered)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('¡Tu pedido ha sido entregado!',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                _buildLeaveReviewAction(order),
              ],
            ),

          if (order.status == OrderStatus.cancelled)
            Text(
                'Tu pedido ha sido cancelado. Motivo: ${order.rejectionReason ?? 'No especificado.'}',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppTheme.error)),

          const SizedBox(height: 16),
          _buildContactSupportButton(order),
        ],
      );
    } else {
      // Vista del Vendedor
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (order.status == OrderStatus.verifying)
            _buildVerifyPaymentAction(order),

          if (order.status == OrderStatus.preparing ||
              order.status == OrderStatus.shipped)
            _buildSellerStatusUpdateActions(order),
        ],
      );
    }
  }

  Widget _buildBuyerTrackingInfo(Order order) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tu pedido ha sido enviado.',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (order.trackingNumber != null &&
                order.trackingNumber!.isNotEmpty)
              _buildInfoRow('No. de Seguimiento:', order.trackingNumber!),
            if (order.estimatedDeliveryDate != null)
              _buildInfoRow(
                  'Fecha estimada de entrega:',
                  DateFormat('dd/MM/yyyy')
                      .format(order.estimatedDeliveryDate!)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement actual tracking link if available
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'La función de seguimiento estará disponible pronto.')),
                );
              },
              icon: const Icon(Icons.track_changes),
              label: const Text('Rastrear Pedido'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerStatusUpdateActions(Order order) {
    _trackingNumberController.text = order.trackingNumber ?? '';
    _selectedEstimatedDeliveryDate = order.estimatedDeliveryDate;
    _estimatedDeliveryDateController.text = order.estimatedDeliveryDate != null
        ? DateFormat('dd/MM/yyyy').format(order.estimatedDeliveryDate!)
        : '';
    _estimatedDeliveryTimeWindowController.text =
        order.deliveryTimeWindow ?? '';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actualizar Estado del Pedido',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (order.deliveryCode != null)
              _buildInfoRow('Código de Entrega:', order.deliveryCode!),
            const SizedBox(height: 16),
            if (order.status == OrderStatus.preparing) ...[
              TextFormField(
                controller: _trackingNumberController,
                decoration: const InputDecoration(
                  labelText: 'Número de Seguimiento (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _estimatedDeliveryDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Fecha Estimada de Entrega (opcional)',
                  border: OutlineInputBorder(),
                ),
                onTap: () => _showEstimatedDeliveryDateTimePicker(order),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _estimatedDeliveryTimeWindowController,
                decoration: const InputDecoration(
                  labelText: 'Ventana de Tiempo (ej. 9:00 AM - 12:00 PM)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () => _updateOrderStatus(
                          order,
                          OrderStatus.shipped,
                          trackingNumber:
                              _trackingNumberController.text.isNotEmpty
                                  ? _trackingNumberController.text
                                  : null,
                          estimatedDeliveryDate: _selectedEstimatedDeliveryDate,
                          deliveryTimeWindow:
                              _estimatedDeliveryTimeWindowController
                                      .text.isNotEmpty
                                  ? _estimatedDeliveryTimeWindowController.text
                                  : null,
                        ),
                icon: const Icon(Icons.send),
                label: const Text('Marcar como Enviado'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
            ],
            if (order.status == OrderStatus.shipped)
              ElevatedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () => _showDeliveryConfirmationDialog(
                        order), // New dialog for delivery confirmation
                icon: const Icon(Icons.check_circle),
                label: const Text('Marcar como Entregado'),
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed:
                  _isProcessing ? null : () => _showCancelOrderDialog(order),
              icon: const Icon(Icons.cancel),
              label: const Text('Cancelar Pedido'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            ),
            const SizedBox(height: 16),
            _buildContactSupportButton(order), // NEW Contact Support Button
          ],
        ),
      ),
    );
  }

  Future<void> _showEstimatedDeliveryDateTimePicker(Order order) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedEstimatedDeliveryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          // ignore: sort_child_properties_last
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            // ignore: sort_child_properties_last
            child: child!,
          );
        },
      );

      if (pickedTime != null && mounted) {
        // Create a DateTime object with the picked date and time
        final DateTime fullPickedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // Generate a time window string, e.g., "10:00 AM - 1:00 PM"
        final DateTime endTime = fullPickedDateTime
            .add(const Duration(hours: 3)); // Example: 3-hour window
        final String startTime = DateFormat('HH:mm').format(fullPickedDateTime);
        final String endTimeString = DateFormat('HH:mm').format(endTime);
        final String timeWindow = '$startTime - $endTimeString';

        setState(() {
          _selectedEstimatedDeliveryDate =
              fullPickedDateTime; // Store the full DateTime
          _estimatedDeliveryDateController.text = DateFormat('dd/MM/yyyy HH:mm')
              .format(fullPickedDateTime); // Display full date and time
          _estimatedDeliveryTimeWindowController.text =
              timeWindow; // Update time window controller
        });
      }
    }
  }

  Future<void> _showDeliveryConfirmationDialog(Order order) async {
    _deliveryCodeConfirmationController.clear();
    String? enteredCode = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Entrega'),
        content: Column(
          mainAxisSize: MainAxisSize.min, // CORREGIDO AQUÍ
          children: [
            const Text(
                'Solicita al comprador el código de entrega para confirmar.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deliveryCodeConfirmationController,
              decoration: const InputDecoration(
                labelText: 'Código de Entrega',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(
                context, _deliveryCodeConfirmationController.text),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (enteredCode != null && mounted) {
      if (enteredCode == order.deliveryCode) {
        await _updateOrderStatus(order, OrderStatus.delivered);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Código de entrega incorrecto.'),
              backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _showCancelOrderDialog(Order order) async {
    _rejectionReasonController.clear(); // Reusing for cancellation reason
    String? reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Pedido'),
        content: TextField(
          controller: _rejectionReasonController,
          decoration: const InputDecoration(
              hintText: 'Motivo de la cancelación (opcional)'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No')),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, _rejectionReasonController.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Sí, Cancelar'), // child movido al final
          ),
        ],
      ),
    );

    if (reason != null && mounted) {
      _updateOrderStatus(order, OrderStatus.cancelled, rejectionReason: reason);
    }
  }

  Widget _buildContactSupportButton(Order order) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContactSupportScreen(orderId: order.id),
          ),
        );
      },
      icon: const Icon(Icons.support_agent),
      label: const Text('Contactar a Soporte para este Pedido'),
      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color chipColor;
    String statusText;

    switch (status) {
      case OrderStatus.pending:
        chipColor = Colors.orange.shade300;
        statusText = 'Pendiente de Pago';
        break;
      case OrderStatus.verifying:
        chipColor = Colors.blue.shade300;
        statusText = 'Verificando Pago';
        break;
      case OrderStatus.preparing:
        chipColor = Colors.cyan.shade300;
        statusText = 'En Preparación';
        break;
      case OrderStatus.shipped:
        chipColor = Colors.indigo.shade300;
        statusText = 'Enviado';
        break;
      case OrderStatus.delivered:
        chipColor = Colors.green.shade300;
        statusText = 'Entregado';
        break;
      case OrderStatus.cancelled:
        chipColor = Colors.red.shade300;
        statusText = 'Cancelado';
        break;
    }

    return Chip(
      backgroundColor: chipColor,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      label: Text(statusText),
    );
  }

  Widget _buildLeaveReviewAction(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('¡Pedido entregado! ¿Qué te parecieron los productos?',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...order.items.map((item) {
          return Card(
            margin: const EdgeInsets.only(top: 8),
            child: ListTile(
              title: Text(item.name),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LeaveReviewScreen(
                      productId: item.productId,
                      orderId: order.id,
                      sellerId: order.sellerId,
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildUploadReceiptAction(Order order) {
    if (_seller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (order.status == OrderStatus.pending &&
            order.rejectionReason != null &&
            order.rejectionReason!.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Motivo de Rechazo del Vendedor:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: AppTheme.error)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: AppTheme.error.withAlpha(25),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: AppTheme.error),
                ),
                child: Text(order.rejectionReason!),
              ),
              const SizedBox(height: 24),
            ],
          ),
        const Text('Instrucciones de Pago del Vendedor:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: AppTheme.primary.withAlpha(128)),
          ),
          child: Text(
            _seller?.paymentInstructions?.isNotEmpty == true
                ? _seller!.paymentInstructions!
                : 'El vendedor no ha proporcionado instrucciones de pago. Por favor, contáctalo por chat.',
          ),
        ),
        const SizedBox(height: 24),
        const Text('Una vez realizado el pago, sube tu comprobante:'),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : () => _uploadReceipt(order),
          icon: _isProcessing
              ? const SizedBox.shrink()
              : const Icon(Icons.upload_file),
          label: _isProcessing
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Subir Comprobante de Pago'),
        ),
      ],
    );
  }

  Widget _buildVerifyPaymentAction(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
            'El comprador ha subido el siguiente comprobante. Por favor, verifica el pago.'),
        const SizedBox(height: 16),
        if (order.paymentReceiptUrl != null &&
            order.paymentReceiptUrl!.isNotEmpty)
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => FullScreenImageViewer(
                        imageUrl: order.paymentReceiptUrl!))),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                order.paymentReceiptUrl!,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error),
              ),
            ),
          )
        else
          const Text('No se ha subido ningún comprobante.'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _isProcessing
                  ? null
                  : () => _handlePaymentVerification(order, true),
              icon: const Icon(Icons.check),
              label: const Text('Confirmar'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            ),
            ElevatedButton.icon(
              onPressed: _isProcessing
                  ? null
                  : () async {
                      _rejectionReasonController.clear();
                      String? reason = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Motivo de Rechazo'),
                          content: TextField(
                            controller: _rejectionReasonController,
                            decoration: const InputDecoration(
                                hintText:
                                    'Introduce el motivo del rechazo (opcional)'),
                            maxLines: 3,
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar')),
                            ElevatedButton(
                                onPressed: () => Navigator.pop(
                                    context, _rejectionReasonController.text),
                                child: const Text('Confirmar')),
                          ],
                        ),
                      );

                      if (reason != null) {
                        _handlePaymentVerification(order, false,
                            rejectionReason: reason);
                      }
                    },
              icon: const Icon(Icons.close),
              label: const Text('Rechazar'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            ),
          ],
        ),
        if (_isProcessing)
          const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Center(child: CircularProgressIndicator())),
      ],
    );
  }
}