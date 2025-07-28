import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // Add `collection` to your pubspec.yaml

enum StatusType { completed, pending, failed, payout }

class EarningsHistoryScreen extends StatelessWidget {
  const EarningsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Sample Data ---
    // Note: Payouts are represented with a negative amount
    final List<Map<String, dynamic>> historyData = [
      {
        'title': 'Trip to Suburbs',
        'date': DateTime.now(), // Today
        'amount': 18.20,
        'status': 'Completed',
        'type': 'trip',
      },
      {
        'title': 'Trip to Airport',
        'date': DateTime.now(), // Today
        'amount': 35.50,
        'status': 'Completed',
        'type': 'trip',
      },
      {
        'title': 'Trip to Downtown',
        'date': DateTime.now().subtract(const Duration(days: 1)), // Yesterday
        'amount': 14.75,
        'status': 'Completed',
        'type': 'trip',
      },
      {
        'title': 'Weekly Payout',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'amount': -328.75, // Negative for debits
        'status': 'Sent',
        'type': 'payout',
      },
      {
        'title': 'Trip to Mall',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'amount': 12.00,
        'status': 'Completed',
        'type': 'trip',
      },
    ];

    // --- Grouping Logic ---
    final groupedData = groupBy(
      historyData,
      (Map<String, dynamic> item) => DateUtils.dateOnly(item['date']),
    );

    // Create a sorted list of dates
    final sortedDates = groupedData.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Sort dates descending

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings History'), elevation: 0),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final itemsForDate = groupedData[date]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateHeader(date: date),
              ...itemsForDate.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _TransactionHistoryItem(
                    title: item['title'],
                    status: item['status'],
                    amount: item['amount'],
                    type: item['type'],
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}

// 🔹 Custom Widget for Date Headers
class _DateHeader extends StatelessWidget {
  final DateTime date;
  const _DateHeader({required this.date});

  String _formatDate(DateTime date) {
    final now = DateUtils.dateOnly(DateTime.now());
    if (date == now) {
      return 'TODAY';
    } else if (date == now.subtract(const Duration(days: 1))) {
      return 'YESTERDAY';
    } else {
      return DateFormat.yMMMMd().format(date).toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
      child: Text(
        _formatDate(date),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
        ),
      ),
    );
  }
}

// 🔹 Custom Widget for a single transaction item
class _TransactionHistoryItem extends StatelessWidget {
  final String title;
  final String status;
  final double amount;
  final String type; // 'trip' or 'payout'

  const _TransactionHistoryItem({
    required this.title,
    required this.status,
    required this.amount,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = amount >= 0;

    final IconData iconData = type == 'payout'
        ? Icons.account_balance_wallet_outlined
        : Icons.directions_car_filled_outlined;
    final Color color = isPositive
        ? Colors.green.shade600
        : Colors.orange.shade700;

    return InkWell(
      onTap: () {
        /* Navigate to details */
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor, width: 1.0),
        ),
        child: Row(
          children: [
            Icon(iconData, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  StatusTag(
                    text: status,
                    type: type == 'payout'
                        ? StatusType.payout
                        : status.toLowerCase() == 'completed'
                        ? StatusType.completed
                        : status.toLowerCase() == 'pending'
                        ? StatusType.pending
                        : StatusType.failed,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              NumberFormat.currency(
                symbol: '₱',
                decimalDigits: 2,
              ).format(amount),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔹 Custom Widget for the small status tag
class StatusTag extends StatelessWidget {
  final String text;
  final StatusType type;

  const StatusTag({super.key, required this.text, required this.type});

  // Helper method to get the right color configuration
  (Color, Color) _getColors(BuildContext context) {
    final theme = Theme.of(context);
    switch (type) {
      case StatusType.completed:
        // Use a professional green for success
        return (Colors.green.shade700, Colors.green.shade100);
      case StatusType.pending:
        // Use a clear orange/yellow for pending states
        return (Colors.orange.shade800, Colors.orange.shade100);
      case StatusType.failed:
        // Use a distinct red for failures
        return (Colors.red.shade700, Colors.red.shade100);
      case StatusType.payout:
        // Use the brand's primary color (pink) for brand-specific actions
        return (theme.primaryColor, theme.primaryColor.withOpacity(0.1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (textColor, backgroundColor) = _getColors(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
