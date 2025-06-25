import 'package:flutter/material.dart';

class PaymentMethodDropdown extends StatelessWidget {
  final String selected;
  final ValueChanged<String?> onChanged;

  const PaymentMethodDropdown({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selected,
      decoration: const InputDecoration(
        labelText: 'Payment Method',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      items: ['Cash', 'Card', 'Wallet']
          .map((method) => DropdownMenuItem(value: method, child: Text(method)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
