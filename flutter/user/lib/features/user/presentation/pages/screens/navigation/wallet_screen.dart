import 'package:flutter/material.dart';
import '../../../widgets/widgets.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomUserAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          WalletBalanceCard(),
          const SizedBox(height: 32),
          const SectionTitle('Payment Methods'),
          const SizedBox(height: 12),
          const PaymentMethodsList(),
          const SizedBox(height: 32),
          const TransactionHeader(),
          const SizedBox(height: 12),
          ...List.generate(3, (index) => const TransactionItem()),
          const SizedBox(height: 32),
          const SectionTitle('Promotions & Credits'),
          const SizedBox(height: 12),
          const PromotionCard(
            title: 'Get \$5 off your next ride',
            subtitle: 'Valid until June 30, 2025',
          ),
          const PromotionCard(
            title: 'Invite a friend & earn rewards',
            subtitle: 'Ongoing',
          ),
          const SizedBox(height: 32),
          const SectionTitle('Spending Analytics'),
          const SizedBox(height: 12),
          const AnalyticsPlaceholder(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
