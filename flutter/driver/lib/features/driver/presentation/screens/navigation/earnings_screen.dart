import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Assuming these are custom widgets from your project.
// Ensure they are correctly implemented.
import '../../widgets/widgets.dart';
import 'earnings/withdraw_screen.dart';
import 'earnings/earnings_history_screen.dart';
import '../../providers/driver_provider.dart';

// 🔹 Earnings Summary Model (Unchanged)
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

// 🔹 Earnings Summary Provider (Unchanged)
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

// 🔹 [FIXED & REFACTORED] Earnings Screen with State and TabController
class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<String> _ranges = ['day', 'week', 'month'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _ranges.length,
      vsync: this,
      initialIndex: 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // The selected range is now managed by the stateful widget's TabController
    final selectedRange = _ranges[_tabController.index];
    final earningsAsync = ref.watch(earningsSummaryProvider(selectedRange));

    return Scaffold(
      appBar: CustomUserAppBar(), // No parameters passed
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // The TabBar is placed here, within the body.
          Container(
            color: theme.scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
              indicatorColor: colorScheme.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Today'),
                Tab(text: 'This Week'),
                Tab(text: 'This Month'),
              ],
              onTap: (index) {
                // When a tab is tapped, we call setState to rebuild the widget.
                // This will re-watch the provider with the new 'selectedRange'.
                setState(() {});
              },
            ),
          ),
          // Use an Expanded widget to allow the ListView to fill the remaining space.
          Expanded(
            child: earningsAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              ),
              error: (err, _) {
                // 🔹 [ADDED] Wrap error view with RefreshIndicator
                // This allows the user to pull-to-refresh even from an error state.
                return RefreshIndicator(
                  color: colorScheme.primary,
                  onRefresh: () => ref.refresh(
                    earningsSummaryProvider(selectedRange).future,
                  ),
                  child: ListView(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(24),
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Text(
                          'An error occurred.\nPull down to try again.\n\n($err)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              data: (summary) {
                // 🔹 [ADDED] Wrap the main content with RefreshIndicator
                return RefreshIndicator(
                  color: colorScheme.primary,
                  // onRefresh requires a Future. ref.refresh invalidates the provider
                  // and returns the new future, which is perfect for this use case.
                  onRefresh: () => ref.refresh(
                    earningsSummaryProvider(selectedRange).future,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: [
                      const SizedBox(height: 16),

                      // Pass the dynamic range to the header card
                      _buildHeaderCard(
                        context,
                        summary,
                        colorScheme,
                        selectedRange,
                      ),

                      const SizedBox(height: 24),

                      _buildTripStats(summary),

                      const SizedBox(height: 32),

                      SectionHeaderWithSeeAll(
                        title: 'Recent Payments',
                        onSeeAll: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EarningsHistoryScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(
                        3,
                        (index) => TransactionItem(
                          title: 'Trip to Downtown',
                          subtitle: 'Wallet • Completed',
                          amount: 14.75 + index,
                          date: DateTime(2025, 6, 17 - index),
                          onTap: () {},
                        ),
                      ),

                      const SizedBox(height: 32),

                      SectionHeaderWithSeeAll(
                        title: 'Bonuses & Promotions',
                        onSeeAll: () {},
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 160,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          children: const [
                            ModernPromotionCard(
                              title: '🔥 Weekly Bonus Challenge',
                              subtitle: 'Complete 30 trips to earn ₱500 extra',
                              icon: Icons.emoji_events_rounded,
                            ),
                            SizedBox(width: 16),
                            ModernPromotionCard(
                              title: '⏰ Peak Hour Boost',
                              subtitle: 'Earn +20% during 5PM–8PM daily',
                              icon: Icons.alarm_on_rounded,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      const SectionTitle('Upcoming Payout'),
                      const SizedBox(height: 12),
                      _buildUpcomingPayout(summary, theme),

                      const SizedBox(height: 48),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    EarningsSummary summary,
    ColorScheme colorScheme,
    String range,
  ) {
    final titleText = switch (range) {
      'day' => 'Today\'s Earnings',
      'week' => 'This Week\'s Earnings',
      'month' => 'This Month\'s Earnings',
      _ => 'Earnings',
    };

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleText,
            style: TextStyle(
              color: colorScheme.onPrimary.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₱${summary.totalEarnings.toStringAsFixed(2)}',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.onPrimary,
                foregroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WithdrawScreen()),
              ),
              child: const Text(
                'Withdraw Funds',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripStats(EarningsSummary summary) {
    return Row(
      children: [
        Expanded(
          child: ModernTripStatTile(
            label: 'Trips',
            value: summary.totalTrips.toString(),
            icon: Icons.directions_car_filled_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ModernTripStatTile(
            label: 'Avg Fare',
            value: '₱${summary.averageFare.toStringAsFixed(2)}',
            icon: Icons.account_balance_wallet_rounded,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: ModernTripStatTile(
            label: 'Rating',
            value: '4.92',
            icon: Icons.star_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingPayout(EarningsSummary summary, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Next Payout',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            '₱${summary.totalEarnings.toStringAsFixed(2)} • Monday',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// 🔹 [REFACTORED] Custom Trip Stat Tile (Theme-Compliant)
class ModernTripStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const ModernTripStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// 🔹 [REFACTORED] Custom Promotion Card (Theme-Compliant Gradient)
class ModernPromotionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const ModernPromotionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 260,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: colorScheme.onPrimary.withOpacity(0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
