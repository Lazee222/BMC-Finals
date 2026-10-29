
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/payment_service.dart';

class XenditWebViewScreen extends StatefulWidget {
  final String invoiceUrl;

  const XenditWebViewScreen({
    super.key,
    required this.invoiceUrl,
  });

  // Create a payment and open the Xendit checkout screen.
  static Future<void> openCheckout(
    BuildContext context,
    int orderId,
  ) async {
    try {
      final payment = await PaymentService().createPayment(orderId);
      final checkoutUrl = payment['checkout_url'] as String;

      if (!context.mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => XenditWebViewScreen(
            invoiceUrl: checkoutUrl,
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not start payment: $error'),
        ),
      );
    }
  }

  @override
  State<XenditWebViewScreen> createState() =>
      _XenditWebViewScreenState();
}

class _XenditWebViewScreenState
    extends State<XenditWebViewScreen> {
  WebViewController? _controller;
  bool _isLoadingPage = true;
  bool _browserOpened = false;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      _launchInBrowser();
    } else {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) {
                setState(() => _isLoadingPage = true);
              }
            },
            onPageFinished: (_) {
              if (mounted) {
                setState(() => _isLoadingPage = false);
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.invoiceUrl));
    }
  }

  Future<void> _launchInBrowser() async {
    if (_browserOpened) return;
    _browserOpened = true;

    final uri = Uri.tryParse(widget.invoiceUrl);

    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        setState(() => _isLoadingPage = false);
      }
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (mounted) {
      setState(() => _isLoadingPage = false);

      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Xendit checkout.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xendit Checkout'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check),
            label: const Text('Done'),
          ),
        ],
      ),
      body: kIsWeb
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.open_in_browser,
                      size: 64,
                      color: Colors.indigo,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Xendit Checkout opened in your browser.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Complete the test payment in the browser, '
                      'then return here and tap Done. '
                      'Payment must still be verified by the server.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () {
                        _browserOpened = false;
                        _launchInBrowser();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Re-open Checkout'),
                    ),
                    if (_isLoadingPage)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                if (_controller != null)
                  WebViewWidget(controller: _controller!),
                if (_isLoadingPage)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
    );
  }
}
