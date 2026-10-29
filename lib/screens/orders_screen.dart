
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/payment_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final PaymentService _paymentService = PaymentService();

  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  // Convert the Supabase UTC timestamp to Philippine time (UTC+8).
  String _formatOrderTime(dynamic dateValue) {
    if (dateValue == null) return 'Date unavailable';

    final parsed = DateTime.tryParse(dateValue.toString());

    if (parsed == null) return 'Date unavailable';

    final philippineTime = parsed.toUtc().add(
      const Duration(hours: 8),
    );

    final date =
        '${philippineTime.day.toString().padLeft(2, '0')}/'
        '${philippineTime.month.toString().padLeft(2, '0')}/'
        '${philippineTime.year}';

    final hour = philippineTime.hour;
    final minute = philippineTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$date  $displayHour:$minute $period ()';
  }

  Future<List<Map<String, dynamic>>> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOrders =
        prefs.getStringList('urban_brew_guest_orders') ?? [];

    final orders = <Map<String, dynamic>>[];

    for (final savedOrder in savedOrders) {
      try {
        final reference =
            Map<String, dynamic>.from(jsonDecode(savedOrder) as Map);

        final orderId = int.tryParse(
          reference['order_id']?.toString() ?? '',
        );

        final phone =
            reference['customer_phone']?.toString() ?? '';

        if (orderId == null || phone.isEmpty) continue;

        final result = await _paymentService.fetchGuestOrder(
          orderId: orderId,
          customerPhone: phone,
        );

        final orderData = result['order'] is Map
            ? Map<String, dynamic>.from(result['order'] as Map)
            : result;

        final rawItems = result['items'] ?? result['order_items'];

        orders.add({
          ...orderData,
          'id': orderData['id'] ?? orderData['order_id'] ?? orderId,
          'items': rawItems is List ? rawItems : [],
          'payment_status': result['payment_status'] ?? 'pending',
        });
      } catch (error) {
        debugPrint('Could not load a saved order: $error');
      }
    }

    orders.sort((a, b) {
      final dateA = DateTime.tryParse(
        a['created_at']?.toString() ?? '',
      );
      final dateB = DateTime.tryParse(
        b['created_at']?.toString() ?? '',
      );

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateB.compareTo(dateA);
    });

    return orders;
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _ordersFuture = _loadOrders();
    });

    await _ordersFuture;
  }

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFFB87945);
    const cream = Color(0xFFF4E9D8);
    const muted = Color(0xFFB7A99A);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh orders',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrders,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: brown),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Could not load orders.',
                    style: TextStyle(color: cream),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _refreshOrders,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.receipt_long,
                    size: 60,
                    color: brown,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No orders found.',
                    style: TextStyle(
                      color: cream,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your orders will appear here after checkout.',
                    style: TextStyle(color: muted),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _refreshOrders,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final orderId = order['id']?.toString() ?? 'Unknown';

              final paymentStatus =
                  order['payment_status']?.toString().toLowerCase() ??
                      'pending';

              final isPaid = paymentStatus == 'paid';

              final statusColor = isPaid
                  ? Colors.green
                  : paymentStatus == 'failed' ||
                          paymentStatus == 'expired'
                      ? Colors.redAccent
                      : Colors.orange;

              final amount = double.tryParse(
                    order['total_amount']?.toString() ?? '',
                  ) ??
                  0.0;

              final dateText = _formatOrderTime(order['created_at']);
              final items = order['items'] as List;

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            color: brown,
                            size: 30,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Order #$orderId',
                              style: const TextStyle(
                                color: cream,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              paymentStatus.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ORDER ITEMS',
                        style: TextStyle(
                          color: brown,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (items.isEmpty)
                        const Text(
                          'Item details unavailable.',
                          style: TextStyle(color: muted),
                        )
                      else
                        ...items.map((item) {
                          final product =
                              Map<String, dynamic>.from(item as Map);

                          final name = product['product_name'] ??
                              product['name'] ??
                              'Product';

                          final quantity = product['quantity'] ?? 1;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '$name × $quantity',
                              style: const TextStyle(color: cream),
                            ),
                          );
                        }),
                      const Divider(height: 24, color: muted),
                      Text(
                        'Total: ₱${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: brown,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: muted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Ordered: $dateText',
                              style: const TextStyle(color: muted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
