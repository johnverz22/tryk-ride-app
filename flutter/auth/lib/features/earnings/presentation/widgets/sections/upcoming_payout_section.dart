import 'package:flutter/material.dart';

import '../earnings_widgets.dart';

class UpcomingPayoutSection extends StatelessWidget {
  const UpcomingPayoutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
        const SectionTitle('Upcoming Payout'),
          const SizedBox(height: 12),
          
          // Upcoming payout details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Next payout',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$328.75 • Monday',
                  style: TextStyle(color: Colors.deepPurple),
                ),
              ],
            ),
          ),
       ],
    );
  }
}