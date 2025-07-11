import 'package:flutter/material.dart';
import '../../../widgets/widgets.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: const Text('Wallet'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
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
          const SectionTitle('Spending Analytics'),
          const SizedBox(height: 12),
          const AnalyticsPlaceholder(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
