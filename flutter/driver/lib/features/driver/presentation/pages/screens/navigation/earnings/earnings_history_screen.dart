import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EarningsHistoryScreen extends StatelessWidget {
  const EarningsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    final List<Map<String, dynamic>> historyData = [
      {
        'title': 'Trip to Airport',
        'date': DateTime(2025, 6, 18),
        'amount': 22.50,
        'status': 'Completed',
      },
      {
        'title': 'Trip to Downtown',
        'date': DateTime(2025, 6, 17),
        'amount': 14.75,
        'status': 'Completed',
      },
      {
        'title': 'Weekly Payout',
        'date': DateTime(2025, 6, 16),
        'amount': 328.75,
        'status': 'Payout Sent',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings History'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: historyData.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = historyData[index];
          return ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Colors.grey[100],
            leading: const Icon(Icons.attach_money, color: Colors.green),
            title: Text(item['title']),
            subtitle: Text(
              DateFormat.yMMMd().format(item['date']),
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(currencyFormatter.format(item['amount']),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    )),
                const SizedBox(height: 4),
                Text(
                  item['status'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                )
              ],
            ),
            onTap: () {
              // Optional: Navigate to a detailed trip or payout screen
            },
          );
        },
      ),
    );
  }
}
