import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EarningsSummaryCard extends StatelessWidget {
  final double amount;
  final String timePeriod;
  final VoidCallback onWithdrawPressed;

  const EarningsSummaryCard({
    super.key,
    required this.amount,
    required this.timePeriod,
    required this.onWithdrawPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnings • $timePeriod',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormatter.format(amount),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onWithdrawPressed,
                icon: const Icon(Icons.money_off, size: 20),
                label: const Text('Withdraw'),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
