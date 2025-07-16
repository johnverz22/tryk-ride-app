import 'package:flutter/material.dart';
import 'payment_option_tile.dart';

class PaymentMethodSection extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onMethodChanged;

  const PaymentMethodSection({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: color.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Payment Method',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                PaymentOptionTile(
                  icon: Icons.money,
                  label: 'Cash',
                  selected: selectedMethod == 'Cash',
                  onTap: () => onMethodChanged('Cash'),
                ),
                PaymentOptionTile(
                  icon: Icons.credit_card,
                  label: 'Card',
                  selected: selectedMethod == 'Card',
                  onTap: () => onMethodChanged('Card'),
                ),
                PaymentOptionTile(
                  icon: Icons.account_balance_wallet,
                  label: 'Wallet',
                  selected: selectedMethod == 'Wallet',
                  onTap: () => onMethodChanged('Wallet'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
