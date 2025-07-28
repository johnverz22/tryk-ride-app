import 'dart:convert';
import 'dart:math'; // Required for the 'max' function on lists
import 'package:driver/config/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fl_chart/fl_chart.dart';

// Assuming these are custom widgets from your project.
// You must ensure they are correctly implemented and imported.
import '../../widgets/widgets.dart';
import 'earnings/withdraw_screen.dart';
import 'earnings/earnings_history_screen.dart';
import '../../providers/driver_provider.dart';

//==============================================================================
// 1. Data Model
//==============================================================================

/// 🔹 Represents the complete earnings summary for a given time range.
/// It's designed to hold data for any of the charts.
class EarningsSummary {
  final double totalEarnings;
  final int totalTrips;
  final double averageFare;
  final double averageRating;

  // Data for the charts, provided by the API based on the requested range.
  final List<double> hourlyEarnings; // For the 'day' chart (24 data points)
  final List<double> dailyEarnings; // For the 'week' chart (7 data points)
  final List<double>
  monthlyEarningsByWeek; // For the 'month' chart (4-5 data points)

  EarningsSummary({
    required this.totalEarnings,
    required this.totalTrips,
    required this.averageFare,
    required this.averageRating,
    required this.hourlyEarnings,
    required this.dailyEarnings,
    required this.monthlyEarningsByWeek,
  });

  /// 🔹 Factory constructor to parse the JSON from the API.
  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse lists of doubles from a dynamic JSON list.
    List<double> toDoubleList(dynamic jsonList) {
      if (jsonList is List) {
        return List<double>.from(jsonList.map((e) => (e ?? 0).toDouble()));
      }
      return []; // Return an empty list if the key is missing or not a list.
    }

    return EarningsSummary(
      totalEarnings: (json['total_earnings'] ?? 0).toDouble(),
      totalTrips: json['total_trips'] ?? 0,
      averageFare: (json['average_fare'] ?? 0).toDouble(),
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      // Parse all potential data arrays. The API will only send one of these
      // depending on the 'range' parameter.
      hourlyEarnings: toDoubleList(json['hourly_earnings']),
      dailyEarnings: toDoubleList(json['daily_earnings']),
      monthlyEarningsByWeek: toDoubleList(json['monthly_earnings_by_week']),
    );
  }
}

//==============================================================================
// 2. Data Provider
//==============================================================================

/// 🔹 Riverpod provider to fetch earnings summary from the API.
/// It takes a 'range' ('day', 'week', 'month') and returns the corresponding data.
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

  // 🔹 No more hardcoded data. We either succeed and parse, or throw an error.
  if (response.statusCode == 200) {
    return EarningsSummary.fromJson(jsonDecode(response.body));
  } else {
    // The UI's .when() will catch this error and display the error view.
    throw Exception('Failed to load earnings: ${response.body}');
  }
});

//==============================================================================
// 3. UI (Screen Widget)
//==============================================================================

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
      initialIndex: 1, // Start on 'This Week'
    );
    // Add a listener to rebuild the UI when the tab changes, which will
    // cause Riverpod to re-fetch data for the new range.
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // Clean up the listener and controller to prevent memory leaks.
    _tabController.removeListener(() {});
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // The selected range is now dynamically read from the TabController's index.
    final selectedRange = _ranges[_tabController.index];
    final earningsAsync = ref.watch(earningsSummaryProvider(selectedRange));

    return Scaffold(
      appBar: CustomUserAppBar(),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // The TabBar to switch between different time ranges.
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
            ),
          ),

          // The main content area that reacts to the provider's state.
          Expanded(
            child: earningsAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              ),
              error: (err, _) => RefreshIndicator(
                color: colorScheme.primary,
                onRefresh: () =>
                    ref.refresh(earningsSummaryProvider(selectedRange).future),
                child: ListView(
                  children: [
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24),
                      height: MediaQuery.of(context).size.height * 0.6,
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
              ),
              data: (summary) {
                return RefreshIndicator(
                  color: colorScheme.primary,
                  onRefresh: () => ref.refresh(
                    earningsSummaryProvider(selectedRange).future,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: [
                      const SizedBox(height: 16),
                      _buildHeaderCard(
                        context,
                        summary,
                        colorScheme,
                        selectedRange,
                      ),
                      const SizedBox(height: 16),

                      // 🔹 This widget now dynamically builds the correct chart.
                      _buildChart(summary, colorScheme, selectedRange),

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
                      // This is still example data, replace with a real transaction list.
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

  //============================================================================
  // 4. Widget Builders
  //============================================================================

  /// 🔹 Main chart builder that selects the correct chart type based on the range.
  Widget _buildChart(
    EarningsSummary summary,
    ColorScheme colorScheme,
    String range,
  ) {
    return switch (range) {
      'day' => _buildHourlyChart(summary, colorScheme),
      'week' => _buildDailyChart(summary, colorScheme),
      'month' => _buildMonthlyChart(summary, colorScheme),
      _ => const SizedBox.shrink(), // Fallback for safety
    };
  }

  /// 🔹 Builds a Line Chart for the 'Today' view, showing earnings by the hour.
  Widget _buildHourlyChart(EarningsSummary summary, ColorScheme colorScheme) {
    if (summary.hourlyEarnings.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    for (int i = 0; i < summary.hourlyEarnings.length; i++) {
      spots.add(FlSpot(i.toDouble(), summary.hourlyEarnings[i]));
    }

    return Column(
      children: [
        const SectionTitle('Earnings by Hour'),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval:
                        3, // Show a label every 3 hours (12A, 3A, 6A, 9A, 12P, 3P, 6P, 9P)
                    getTitlesWidget: (value, meta) {
                      final style = TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      );
                      String text;
                      switch (value.toInt()) {
                        case 0:
                          text = '12A';
                          break;
                        case 3:
                          text = '3AM';
                          break;
                        case 6:
                          text = '6AM';
                          break;
                        case 9:
                          text = '9AM';
                          break;
                        case 12:
                          text = '12P';
                          break;
                        case 15:
                          text = '3PM';
                          break;
                        case 18:
                          text = '6PM';
                          break;
                        case 21:
                          text = '9PM';
                          break;
                        default:
                          return const SizedBox.shrink(); // Hide other labels
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(text, style: style),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: colorScheme.primary,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withOpacity(0.4),
                        colorScheme.primary.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 🔹 Builds a Bar Chart for the 'This Week' view, showing earnings per day.
  Widget _buildDailyChart(EarningsSummary summary, ColorScheme colorScheme) {
    if (summary.dailyEarnings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Daily Breakdown'),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY:
                  summary.dailyEarnings.reduce(max) *
                  1.2, // Dynamic max Y with 20% padding
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      currencyFormatter.format(rod.toY),
                      TextStyle(
                        color: colorScheme.onSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final style = TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      );
                      String text;
                      switch (value.toInt()) {
                        case 0:
                          text = 'M';
                          break;
                        case 1:
                          text = 'T';
                          break;
                        case 2:
                          text = 'W';
                          break;
                        case 3:
                          text = 'T';
                          break;
                        case 4:
                          text = 'F';
                          break;
                        case 5:
                          text = 'S';
                          break;
                        case 6:
                          text = 'S';
                          break;
                        default:
                          text = '';
                          break;
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(text, style: style),
                      );
                    },
                    reservedSize: 38,
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              barGroups: List.generate(summary.dailyEarnings.length, (index) {
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: summary.dailyEarnings[index],
                      color: colorScheme.primary,
                      width: 22,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  /// 🔹 Builds a Bar Chart for the 'This Month' view, showing earnings per week.
  Widget _buildMonthlyChart(EarningsSummary summary, ColorScheme colorScheme) {
    if (summary.monthlyEarningsByWeek.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Weekly Breakdown'),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: summary.monthlyEarningsByWeek.reduce(max) * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      currencyFormatter.format(rod.toY),
                      TextStyle(
                        color: colorScheme.onSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final style = TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      );
                      final text = 'Week ${value.toInt() + 1}';
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(text, style: style),
                      );
                    },
                    reservedSize: 38,
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              barGroups: List.generate(summary.monthlyEarningsByWeek.length, (
                index,
              ) {
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: summary.monthlyEarningsByWeek[index],
                      color: colorScheme.primary,
                      width: 35, // Wider bars for the monthly view
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the main header card displaying total earnings.
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
            currencyFormatter.format(summary.totalEarnings),
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

  /// Builds the row of statistic tiles (Trips, Avg Fare, Rating).
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
            value: currencyFormatter.format(summary.averageFare),
            icon: Icons.account_balance_wallet_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ModernTripStatTile(
            label: 'Rating',
            value: summary.averageRating.toStringAsFixed(1),
            icon: Icons.star_rounded,
          ),
        ),
      ],
    );
  }

  /// Builds the upcoming payout information card.
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
            '${currencyFormatter.format(summary.totalEarnings)} • Monday',
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
