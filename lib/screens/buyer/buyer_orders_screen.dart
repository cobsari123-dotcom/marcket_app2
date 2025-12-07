import 'package:flutter/material.dart';
import 'package:marcket_app/models/order.dart';
import 'package:marcket_app/providers/order_list_provider.dart';
import 'package:marcket_app/screens/common/order_detail_screen.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BuyerOrdersScreen extends StatefulWidget {
  const BuyerOrdersScreen({super.key});

  @override
  State<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends State<BuyerOrdersScreen> {
  final ScrollController _scrollController = ScrollController();
  late OrderListProvider _orderListProvider;

  @override
  void initState() {
    super.initState();
    _orderListProvider = Provider.of<OrderListProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _orderListProvider.init();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          _orderListProvider.hasMoreOrders &&
          !_orderListProvider.isLoadingMore) {
        _orderListProvider.loadMoreOrders();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color chipColor;
    String statusText;

    switch (status) {
      case OrderStatus.pending:
        chipColor = Colors.orange.shade200;
        statusText = 'Pendiente de Pago';
        break;
      case OrderStatus.verifying:
        chipColor = Colors.blue.shade200;
        statusText = 'Verificando Pago';
        break;
      case OrderStatus.preparing:
        chipColor = Colors.cyan.shade200;
        statusText = 'En Preparación';
        break;
      case OrderStatus.shipped:
        chipColor = Colors.indigo.shade200;
        statusText = 'Enviado';
        break;
      case OrderStatus.delivered:
        chipColor = Colors.green.shade200;
        statusText = 'Entregado';
        break;
      case OrderStatus.cancelled:
        chipColor = Colors.red.shade200;
        statusText = 'Cancelado';
        break;
    }

    return Chip(
      label: Text(statusText),
      backgroundColor: chipColor,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800), // Limit width for order list
        child: Consumer<OrderListProvider>(
          builder: (context, provider, child) {
            if (provider.isLoadingInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.errorMessage != null) {
              return Center(child: Text('Error: ${provider.errorMessage}'));
            }
            if (provider.orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long, size: 80, color: AppTheme.primary),
                    const SizedBox(height: 20),
                    Text(
                      'No has realizado pedidos.',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.init(),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8.0),
                itemCount: provider.orders.length + (provider.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == provider.orders.length) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final order = provider.orders[index];
                  return Card(
                    elevation: 2.0,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16.0),
                      title: Text(
                        'Pedido #${order.id.substring(0, 6)}...',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text('Fecha: ${DateFormat('dd/MM/yyyy').format(order.createdAt)}'),
                          const SizedBox(height: 4),
                          Text('Total: \$${order.totalPrice.toStringAsFixed(2)}'),
                        ],
                      ),
                      trailing: _buildStatusChip(order.status),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailScreen(orderId: order.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
