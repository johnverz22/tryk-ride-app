import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'section_title.dart';

class TransactionHeader extends StatelessWidget {
  const TransactionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SectionTitle('Transaction History'),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.filter_alt_outlined, size: 18),
          label: const Text('Filter'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class TransactionItem extends StatelessWidget {
  const TransactionItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color.fromARGB(25, 76, 175, 80),
          ),
          child: const Icon(Icons.directions_car, color: Colors.green),
        ),
        title: const Text('Trip to Golden Gate Park'),
        subtitle: Text(DateFormat('MMMM dd, yyyy – \$12.50').format(DateTime(2025, 6, 17))),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}
