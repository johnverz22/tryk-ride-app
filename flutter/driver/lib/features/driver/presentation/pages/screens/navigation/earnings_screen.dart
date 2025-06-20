import 'package:flutter/material.dart';
import '../../../widgets/widgets.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomUserAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔹 Weekly Earnings Summary
          const EarningsSummaryCard(
            amount: 328.75,
            timePeriod: 'This Week',
          ),
          const SizedBox(height: 24),

          // 🔹 Trip Stats Overview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              TripStatTile(label: 'Trips', value: '42'),
              TripStatTile(label: 'Online Hours', value: '21.3'),
              TripStatTile(label: 'Avg Rating', value: '4.92'),
            ],
          ),
          const SizedBox(height: 32),

          // 🔹 Recent Trip Payments
          const SectionTitle('Recent Trip Payments'),
          const SizedBox(height: 12),
          ...List.generate(5, (index) {
            return TransactionItem(
              title: 'Trip to Downtown',
              subtitle: 'Wallet • Completed',
              amount: 14.75,
              date: DateTime(2025, 6, 17),
              onTap: () {
                // Navigate to trip details if needed
              },
            );
          }),
          const SizedBox(height: 32),

          // 🔹 Driver Bonuses & Promotions
          const SectionTitle('Bonuses & Promotions'),
          const SizedBox(height: 12),
          const PromotionCard(
            title: '🔥 Weekly Bonus Challenge',
            subtitle: 'Complete 30 trips to earn \$50 extra',
          ),
          const PromotionCard(
            title: 'Peak Hour Boost',
            subtitle: 'Earn +20% during 5PM–8PM daily',
          ),

          const SizedBox(height: 40),

          // 🔹 Placeholder for future payout insights
          const SectionTitle('Upcoming Payout'),
          const SizedBox(height: 12),
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

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
