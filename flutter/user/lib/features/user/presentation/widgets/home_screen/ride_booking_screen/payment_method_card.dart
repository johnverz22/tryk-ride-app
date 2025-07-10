import 'package:flutter/material.dart';
import 'package:user/config/currency.dart';
import '../../widgets.dart';

class PaymentMethodCard extends StatelessWidget {
  final String selectedMethod;
  final void Function(String) onSelect;
  final double walletBalance;

  const PaymentMethodCard({
    required this.selectedMethod,
    required this.onSelect,
    required this.walletBalance,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                onTap: () => onSelect('Cash'),
              ),
              PaymentOptionTile(
                icon: Icons.credit_card,
                label: 'Card',
                selected: selectedMethod == 'Card',
                onTap: () => onSelect('Card'),
              ),
              PaymentOptionTile(
                icon: Icons.account_balance_wallet,
                label: 'Wallet',
                selected: selectedMethod == 'Wallet',
                onTap: () => onSelect('Wallet'),
              ),
            ],
          ),
          if (selectedMethod == 'Wallet') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: color.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Wallet Balance: ${currencyFormatter.format(walletBalance)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
