import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user/features/profile/presentation/providers/payment_info_provider.dart';

class PaymentMethodCard extends ConsumerWidget {
  final String selectedMethod;
  final void Function(String) onSelect;

  const PaymentMethodCard({
    required this.selectedMethod,
    required this.onSelect,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final cards = ref.watch(cardsProvider);

    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: color.primary, size: 24),
              const SizedBox(width: 10),
              Text(
                'Payment Method',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main wallet (app wallet)
          if (wallet != null) ...[
            _buildPaymentOption(
              context,
              icon: Icons.account_balance_wallet,
              label: 'Wallet',
              subtitle: 'Balance: ${wallet.formattedBalance}',
              selected: selectedMethod == 'Wallet',
              onTap: () => onSelect('Wallet'),
            ),
            const SizedBox(height: 10),
          ],

          // Digital wallets (not fetched — static list)
          _buildPaymentOption(
            context,
            icon: Icons.phone_iphone,
            label: 'GCash',
            subtitle: 'GCash Wallet',
            selected: selectedMethod == 'gcash',
            onTap: () => onSelect('gcash'),
          ),
          const SizedBox(height: 10),
          _buildPaymentOption(
            context,
            icon: Icons.account_balance_wallet,
            label: 'Maya',
            subtitle: 'Maya Wallet',
            selected: selectedMethod == 'maya',
            onTap: () => onSelect('maya'),
          ),
          const SizedBox(height: 10),

          // Cards (from API)
          for (final card in cards) ...[
            _buildPaymentOption(
              context,
              icon: Icons.credit_card,
              label: card.provider,
              subtitle: '•••• •••• •••• ${card.lastFour}',
              selected: selectedMethod == card.id,
              onTap: () => onSelect(card.id),
            ),
            const SizedBox(height: 10),
          ],

          // Cash (always last)
          _buildPaymentOption(
            context,
            icon: Icons.money,
            label: 'Cash',
            selected: selectedMethod == 'Cash',
            onTap: () => onSelect('Cash'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? color.primary.withValues(alpha: .1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color.primary : Colors.grey[300]!,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? color.primary : Colors.black54),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected ? color.primary : Colors.black87,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: color.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
