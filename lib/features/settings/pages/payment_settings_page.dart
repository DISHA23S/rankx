import 'package:flutter/material.dart';

class PaymentSettingsPage extends StatelessWidget {
  const PaymentSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Checkout Page Content',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This page explains payment details.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildPaymentInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Methods',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'We support secure payments through:',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 12),
        _buildPaymentMethod('UPI'),
        _buildPaymentMethod('Debit Card'),
        _buildPaymentMethod('Credit Card'),
        _buildPaymentMethod('Net Banking'),
        _buildPaymentMethod('Wallets'),
      ],
    );
  }

  Widget _buildPaymentMethod(String method) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.payment, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Text(method, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
