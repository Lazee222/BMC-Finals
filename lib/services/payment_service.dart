
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get products from Supabase.
  Future<List<Product>> fetchProducts() async {
    final response = await _supabase
        .from('products')
        .select()
        .order('id', ascending: true);

    return (response as List)
        .map((item) => Product.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  // Create a payment for an existing order.
  Future<Map<String, dynamic>> createPayment(int orderId) async {
    final response = await _supabase.functions.invoke(
      'create-xendit-payment',
      body: {'order_id': orderId},
    );

    if (response.status != 200) {
      throw Exception('Failed to create payment: ${response.data}');
    }

    final result = Map<String, dynamic>.from(response.data as Map);

    if (result['checkout_url'] == null) {
      throw Exception('Xendit checkout URL was not returned.');
    }

    return result;
  }

  // Check payment status by payment reference.
  Future<String> checkOrderStatus(String paymentReference) async {
    final record = await _supabase
        .from('payments')
        .select('status')
        .eq('payment_reference', paymentReference)
        .maybeSingle();

    return record?['status']?.toString() ?? 'pending';
  }

  // Look up a guest order securely through the Edge Function.
  Future<Map<String, dynamic>> fetchGuestOrder({
    required int orderId,
    required String customerPhone,
  }) async {
    final response = await _supabase.functions.invoke(
      'lookup-guest-order',
      body: {
        'order_id': orderId,
        'customer_phone': customerPhone.trim(),
      },
    );

    if (response.status != 200) {
      final data = response.data;
      final message = data is Map
          ? data['error']?.toString()
          : null;
      throw Exception(message ?? 'Could not load order.');
    }

    return Map<String, dynamic>.from(response.data as Map);
  }
}
  