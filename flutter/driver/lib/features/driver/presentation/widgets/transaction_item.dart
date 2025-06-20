import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionItem extends StatelessWidget {
  final String title;
  final String subtitle; // e.g., "Wallet • Completed"
  final double amount;
  final DateTime date;
  final VoidCallback? onTap;

  const TransactionItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('MMM dd, yyyy').format(date);
    final isPositive = amount >= 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPositive
                ? const Color.fromARGB(25, 76, 175, 80)
                : const Color.fromARGB(25, 244, 67, 54),
          ),
          child: Icon(
            Icons.directions_car,
            color: isPositive ? Colors.green : Colors.red,
          ),
        ),
        title: Text(title),
        subtitle: Text('$dateFormatted • $subtitle'),
        trailing: Text(
          '${isPositive ? '+' : '-'}\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: isPositive ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
