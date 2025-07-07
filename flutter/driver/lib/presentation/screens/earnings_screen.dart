import 'package:driver/presentation/widgets/earnings_widget/trip_stat_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:driver/presentation/widgets/earnings_widget/earnings_widgets.dart'; // Assumes CustomUserAppBar & TripSearchBar are here

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔹 Weekly Earnings Summary
          EarningsSummaryCard(),
          const SizedBox(height: 24),

          // 🔹 Trip Stats Overview
          TripStatBarWidget(),
          const SizedBox(height: 32),

          // 🔹 Recent Trip Payments
          const PaymentTripHistoryWidget(),
          const SizedBox(height: 32),

          // 🔹 Placeholder for future payout insights
          const UpcomingPayoutSection(),
        ],
    );
  }
}
