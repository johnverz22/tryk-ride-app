import 'package:flutter/material.dart';
import '../../../widgets/widgets.dart';
import 'earnings/withdraw_screen.dart';
import 'earnings/earnings_history_screen.dart';
import 'package:provider/provider.dart';
import '../../../providers/driver_provider.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomUserAppBar(
        isOnline: driverProvider.isOnline,
        onToggleOnline: (val) => driverProvider.setOnlineStatus(val),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          EarningsSummaryCard(
            amount: 328.75,
            timePeriod: 'This Week',
            onWithdrawPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WithdrawScreen()),
              );
            },
          ),
          const SizedBox(height: 24),

          // 🔹 Trip Stats
          Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  TripStatTile(label: 'Trips', value: '42'),
                  TripStatTile(label: 'Online Hours', value: '21.3'),
                  TripStatTile(label: 'Avg Rating', value: '4.92'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // 🔹 Recent Trip Payments
          SectionHeaderWithSeeAll(
            title: 'Recent Trip Payments',
            onSeeAll: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EarningsHistoryScreen()),
              );
            },
          ),

          const SizedBox(height: 12),
          ...List.generate(5, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TransactionItem(
                title: 'Trip to Downtown',
                subtitle: 'Wallet • Completed',
                amount: 14.75,
                date: DateTime(2025, 6, 17),
                onTap: () {
                  // TODO: Navigate to trip details
                },
              ),
            );
          }),
          const SizedBox(height: 32),

          // 🔹 Bonuses & Promotions
          SectionHeaderWithSeeAll(
            title: 'Bonuses & Promotions',
            onSeeAll: () {
              // TODO: Navigate to promotions list
            },
          ),
          const SizedBox(height: 12),
          const PromotionCard(
            title: '🔥 Weekly Bonus Challenge',
            subtitle: 'Complete 30 trips to earn \$50 extra',
          ),
          const SizedBox(height: 10),
          const PromotionCard(
            title: '⏰ Peak Hour Boost',
            subtitle: 'Earn +20% during 5PM–8PM daily',
          ),
          const SizedBox(height: 32),

          // 🔹 Upcoming Payout
          const SectionTitle('Upcoming Payout'),
          const SizedBox(height: 12),
          Card(
            elevation: 1,
            color: Colors.deepPurple.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Next Payout',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  Text(
                    '\$328.75 • Monday',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
