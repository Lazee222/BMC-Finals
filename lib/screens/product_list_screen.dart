
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/payment_service.dart';
import 'orders_screen.dart';
import 'guest_checkout_screen.dart';

const Color coffeeBackground = Color(0xFF151311);
const Color coffeeCard = Color(0xFF24201C);
const Color coffeeBrown = Color(0xFFB87945);
const Color coffeeCream = Color(0xFFF4E9D8);
const Color coffeeMuted = Color(0xFFB7A99A);

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final PaymentService _paymentService = PaymentService();

  late Future<List<Product>> _productsFuture;
  final Map<Product, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _productsFuture = _paymentService.fetchProducts();
  }

  int get _cartCount =>
      _cart.values.fold(0, (total, quantity) => total + quantity);

  double get _cartTotal => _cart.entries.fold(
        0.0,
        (total, item) => total + item.key.price * item.value,
      );

  void _addToCart(Product product) {
    setState(() {
      _cart[product] = (_cart[product] ?? 0) + 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to your cart ☕'),
        duration: const Duration(seconds: 1),
        backgroundColor: coffeeBrown,
      ),
    );
  }

  void _changeQuantity(Product product, int change) {
    setState(() {
      final newQuantity = (_cart[product] ?? 0) + change;

      if (newQuantity <= 0) {
        _cart.remove(product);
      } else {
        _cart[product] = newQuantity;
      }
    });
  }

  Widget _productImage(String imageUrl, {double size = 160}) {
    return SizedBox(
      width: size,
      height: size,
      child: imageUrl.trim().isEmpty
          ? const ColoredBox(
              color: coffeeCard,
              child: Icon(
                Icons.coffee,
                size: 55,
                color: coffeeBrown,
              ),
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: coffeeCard,
                child: Icon(
                  Icons.coffee,
                  size: 55,
                  color: coffeeBrown,
                ),
              ),
            ),
    );
  }

  void _openCart() {
    showModalBottomSheet(
      context: context,
      backgroundColor: coffeeCard,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void updateQuantity(Product product, int change) {
              _changeQuantity(product, change);
              setSheetState(() {});
            }

            return Padding(
              padding: const EdgeInsets.all(20),
              child: SafeArea(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Coffee Cart ☕',
                        style: TextStyle(
                          color: coffeeCream,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Your next favorite cup is waiting.',
                        style: TextStyle(color: coffeeMuted),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _cart.isEmpty
                            ? const Center(
                                child: Text(
                                  'Your cart is empty. Add a coffee!',
                                  style: TextStyle(color: coffeeMuted),
                                ),
                              )
                            : ListView(
                                children: _cart.entries.map((item) {
                                  final product = item.key;
                                  final quantity = item.value;

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: _productImage(
                                        product.imageUrl,
                                        size: 55,
                                      ),
                                    ),
                                    title: Text(
                                      product.name,
                                      style: const TextStyle(
                                        color: coffeeCream,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '₱${product.price.toStringAsFixed(2)} each',
                                      style: const TextStyle(
                                        color: coffeeMuted,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () =>
                                              updateQuantity(product, -1),
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: coffeeBrown,
                                          ),
                                        ),
                                        Text(
                                          '$quantity',
                                          style: const TextStyle(
                                            color: coffeeCream,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              updateQuantity(product, 1),
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            color: coffeeBrown,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                      const Divider(color: coffeeMuted),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              color: coffeeCream,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₱${_cartTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: coffeeBrown,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: coffeeBrown,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                          ),
                          onPressed: _cart.isEmpty
                              ? null
                              : () {
                                  Navigator.pop(sheetContext);
                                  Navigator.push(
                                    this.context,
                                    MaterialPageRoute(
                                      builder: (_) => GuestCheckoutScreen(
                                        cart: Map<Product, int>.from(_cart),
                                        total: _cartTotal,
                                      ),
                                    ),
                                  );
                                },
                          child: const Text('Proceed to Checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF39271D),
            Color(0xFF211A15),
            coffeeBackground,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: coffeeBrown.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.coffee,
                  color: coffeeBrown,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'URBAN BREW',
                    style: TextStyle(
                      color: coffeeCream,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'YOUR DAILY COFFEE RITUAL',
                    style: TextStyle(
                      color: coffeeMuted,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'Good coffee.',
            style: TextStyle(
              color: coffeeCream,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Better mood.',
            style: TextStyle(
              color: coffeeBrown,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your favorite cup, made for your everyday moments.',
            style: TextStyle(
              color: coffeeMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: coffeeCard,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: coffeeBrown.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_cafe, color: coffeeBrown, size: 19),
                SizedBox(width: 8),
                Text(
                  'BREWED FRESH. SERVED WITH LOVE.',
                  style: TextStyle(
                    color: coffeeCream,
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: coffeeBackground,
      appBar: AppBar(
        backgroundColor: coffeeBackground,
        foregroundColor: coffeeCream,
        title: const Text(
          'Urban Brew',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Order History',
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OrdersScreen(),
                ),
              );
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Coffee Cart',
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: _openCart,
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 4,
                  top: 3,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: coffeeBrown,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: coffeeBrown),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Could not load products.\n${snapshot.error}',
                  style: const TextStyle(color: coffeeCream),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(
              child: Text(
                'No coffee products found yet.',
                style: TextStyle(color: coffeeCream),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1000
                  ? 4
                  : constraints.maxWidth >= 650
                      ? 3
                      : 2;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OUR MENU',
                                style: TextStyle(
                                  color: coffeeBrown,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Find your brew',
                                style: TextStyle(
                                  color: coffeeCream,
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${products.length} drinks',
                            style: const TextStyle(color: coffeeMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.66,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = products[index];

                          return Container(
                            decoration: BoxDecoration(
                              color: coffeeCard,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      _productImage(product.imageUrl),
                                      Positioned(
                                        top: 10,
                                        left: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: coffeeBackground.withValues(
                                              alpha: 0.88,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            'FRESH BREW',
                                            style: TextStyle(
                                              color: coffeeBrown,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(11, 12, 11, 4),
                                  child: Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: coffeeCream,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 11),
                                  child: Text(
                                    '₱${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: coffeeBrown,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(9),
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: coffeeBrown,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () => _addToCart(product),
                                    icon: const Icon(
                                      Icons.add,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Add to Cart',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: products.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
