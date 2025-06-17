import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final methods = [
      {'type': 'Visa', 'number': '**** **** **** 4582', 'expiry': '05/2026', 'default': true},
      {'type': 'Mastercard', 'number': '**** **** **** 7865', 'expiry': '11/2025', 'default': false},
      {'type': 'PayPal', 'email': 'alex.thompson@example.com', 'default': false},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: methods.length,
        itemBuilder: (_, i) {
          final m = methods[i];
          return Card(
            child: ListTile(
              title: Text(m['type'] as String),
              subtitle: Text(m.containsKey('number') ? '${m['number']}\nExpires ${m['expiry']}' : m['email'] as String),
              trailing: m['default'] == true ? const Chip(label: Text('Default')) : null,
            ),
          );
        },
      ),
    );
  }
}
