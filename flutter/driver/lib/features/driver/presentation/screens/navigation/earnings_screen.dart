import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../widgets/widgets.dart';
import 'earnings/withdraw_screen.dart';
import 'earnings/earnings_history_screen.dart';
import '../../providers/driver_provider.dart'; // adjust if needed

// 🔹 Earnings Summary Model
class EarningsSummary {
  final double totalEarnings;
  final int totalTrips;
  final double averageFare;

  EarningsSummary({
    required this.totalEarnings,
    required this.totalTrips,
    required this.averageFare,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      totalEarnings: (json['total_earnings'] ?? 0).toDouble(),
      totalTrips: json['total_trips'] ?? 0,
      averageFare: (json['average_fare'] ?? 0).toDouble(),
    );
  }
}

// 🔹 Earnings Summary Provider with dynamic range support
final earningsSummaryProvider = FutureProvider.family<EarningsSummary, String>((
  ref,
  range,
) async {
  final driver = ref.watch(driverProvider).value;

  if (driver == null || driver.token == null) {
    throw Exception('Driver not authenticated');
  }

  final token = driver.token!;
  final baseUrl = dotenv.env['BASE_URL'];
  final url = Uri.parse('$baseUrl/api/driver/earnings?range=$range');

  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    return EarningsSummary.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load earnings: ${response.body}');
  }
});

// 🔹 Earnings Screen UI
class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const range = 'week'; // Can change to 'day' or 'month'
    final earningsAsync = ref.watch(earningsSummaryProvider(range));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomUserAppBar(),
      body: earningsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (summary) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              // 🔹 Earnings Summary Card
              EarningsSummaryCard(
                amount: summary.totalEarnings,
                timePeriod: 'This Week', // Match the selected range
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TripStatTile(
                        label: 'Trips',
                        value: summary.totalTrips.toString(),
                      ),
                      TripStatTile(
                        label: 'Avg Fare',
                        value: '₱${summary.averageFare.toStringAsFixed(2)}',
                      ),
                      const TripStatTile(
                        label: 'Avg Rating',
                        value: '4.92',
                      ), // Optional: Replace with dynamic rating
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
                    MaterialPageRoute(
                      builder: (_) => const EarningsHistoryScreen(),
                    ),
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
                  // TODO: Navigate to promotions
                },
              ),
              const SizedBox(height: 12),
              const PromotionCard(
                title: '🔥 Weekly Bonus Challenge',
                subtitle: 'Complete 30 trips to earn ₱500 extra',
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Next Payout',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '₱${summary.totalEarnings.toStringAsFixed(2)} • Monday',
                        style: const TextStyle(
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
          );
        },
      ),
    );
  }
}
