
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_model.dart';

class GuestCheckoutScreen extends StatefulWidget {
  final Map<Product, int> cart;
  final double total;

  const GuestCheckoutScreen({
    super.key,
    required this.cart,
    required this.total,
  });

  @override
  State<GuestCheckoutScreen> createState() =>
      _GuestCheckoutScreenState();
}

class _GuestCheckoutScreenState extends State<GuestCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Save the order reference automatically for Order History.
  Future<void> _saveOrderReference(
    String orderId,
    String phone,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final savedOrders =
        prefs.getStringList('urban_brew_guest_orders') ?? [];

    // Avoid saving the same order twice.
    final alreadySaved = savedOrders.any((entry) {
      final order = jsonDecode(entry) as Map<String, dynamic>;
      return order['order_id'].toString() == orderId;
    });

    if (!alreadySaved) {
      savedOrders.add(
        jsonEncode({
          'order_id': orderId,
          'customer_phone': phone,
        }),
      );

      await prefs.setStringList(
        'urban_brew_guest_orders',
        savedOrders,
      );
    }
  }

  Future<void> _proceedToPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final supabase = Supabase.instance.client;
      final phone = _phoneController.text.trim();

      final response = await supabase.functions.invoke(
        'create-xendit-payment',
        body: {
          'customer_name': _nameController.text.trim(),
          'customer_phone': phone,
          'delivery_address': _addressController.text.trim(),
          'items': widget.cart.entries.map((item) {
            return {
              'product_id': item.key.id,
              'quantity': item.value,
            };
          }).toList(),
        },
      );

      if (response.status != 200) {
        throw Exception('Checkout failed: ${response.data}');
      }

      final result =
          Map<String, dynamic>.from(response.data as Map);

      final checkoutUrl = result['checkout_url']?.toString();
      final orderId = result['order_id']?.toString();

      if (orderId == null || orderId.isEmpty) {
        throw Exception('The order ID was not returned.');
      }

      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw Exception('Xendit did not return a checkout URL.');
      }

      // Save the order before opening the payment page.
      await _saveOrderReference(orderId, phone);

      final uri = Uri.tryParse(checkoutUrl);

      const allowedHosts = {
        'checkout.xendit.co',
        'checkout-staging.xendit.co',
      };

      if (uri == null ||
          uri.scheme != 'https' ||
          !allowedHosts.contains(uri.host.toLowerCase())) {
        throw Exception('The checkout URL is invalid.');
      }

      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        throw Exception('Could not open the payment page.');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Order saved! You can view it in Order History. '
            'Payment status will update after confirmation.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: const Color(0xFFB87945),
      ),
      filled: true,
      fillColor: const Color(0xFF24201C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF40352D),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFF4E9D8);
    const brown = Color(0xFFB87945);
    const muted = Color(0xFFB7A99A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guest Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.local_cafe,
                color: brown,
                size: 52,
              ),
              const SizedBox(height: 10),
              const Text(
                'Almost there, coffee lover!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cream,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your delivery details. No account needed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 28),

              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration(
                  'Full name',
                  Icons.person_outline,
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Please enter your name.'
                        : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _decoration(
                  'Phone number',
                  Icons.phone_outlined,
                ),
                validator: (value) =>
                    value == null || value.trim().length < 7
                        ? 'Please enter a valid phone number.'
                        : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration(
                  'Complete delivery address',
                  Icons.location_on_outlined,
                ),
                validator: (value) =>
                    value == null || value.trim().length < 8
                        ? 'Please enter your complete address.'
                        : null,
              ),
              const SizedBox(height: 24),

              const Text(
                'YOUR ORDER',
                style: TextStyle(
                  color: brown,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              ...widget.cart.entries.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.key.name} × ${item.value}',
                          style: const TextStyle(color: cream),
                        ),
                      ),
                      Text(
                        '₱${(item.key.price * item.value).toStringAsFixed(2)}',
                        style: const TextStyle(color: cream),
                      ),
                    ],
                  ),
                );
              }),

              const Divider(color: muted, height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Order total',
                    style: TextStyle(
                      color: cream,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₱${widget.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: brown,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _loading ? null : _proceedToPayment,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.lock_outline),
                label: Text(
                  _loading
                      ? 'Preparing checkout...'
                      : 'Continue to Xendit Payment',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your payment will be processed through the Xendit checkout page.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
