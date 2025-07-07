import 'package:flutter/material.dart';

import '../earnings_widgets.dart';

class PaymentTripHistoryWidget extends StatelessWidget {
  const PaymentTripHistoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Recent Trip Payments'),
        const SizedBox(height: 12),
        ...List.generate(5, (index) {
          return RecentTripCard(
            title: 'Trip to Downtown',
            subtitle: 'Wallet • Completed',
            amount: 14.75,
            date: DateTime(2025, 6, 17),
            onTap: () {
              // Navigate to trip details if needed
            },
          );
        }),
      ],
    );
  }
}