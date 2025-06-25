import 'package:flutter/material.dart';

import '../earnings_widgets.dart';

class BonusesPromotionsSection extends StatelessWidget {
  const BonusesPromotionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bonuses & Promotions'),
        backgroundColor: Colors.pink,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionTitle('Bonuses & Promotions'),
          SizedBox(height: 12),
          PromotionCard(
            title: '🔥 Weekly Bonus Challenge',
            subtitle: 'Complete 30 trips to earn \$50 extra',
          ),
          PromotionCard(
            title: 'Peak Hour Boost',
            subtitle: 'Earn +20% during 5PM–8PM daily',
          ),
        ],
      ),
    );
  }
}