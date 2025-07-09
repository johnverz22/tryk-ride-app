import 'package:flutter/material.dart';
import '../../../../widgets/widgets.dart'; // Your custom button/widget imports

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final appWallet = {
      'type': 'Tryk Wallet',
      'balance': '₱42.50',
      'default': true,
    };

    final digitalWallets = [
      {'type': 'Gcash', 'email': 'alex@example.com', 'default': false},
      {'type': 'Maya', 'email': 'alex@gmail.com', 'default': false},
    ];

    final cards = [
      {
        'type': 'Visa',
        'number': '**** **** **** 4582',
        'expiry': '05/2026',
        'default': false,
      },
      {
        'type': 'Mastercard',
        'number': '**** **** **** 7865',
        'expiry': '11/2025',
        'default': false,
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
        children: [
          _buildSectionTitle('App Wallet'),
          _buildAppWalletCard(appWallet, theme),

          const SizedBox(height: 24),
          _buildSectionTitle('Digital Wallets'),
          ...digitalWallets.map((m) => _buildWalletCard(m, theme)).toList(),
          _buildAddMethodButton('Add Digital Wallet'),

          const SizedBox(height: 24),
          _buildSectionTitle('Credit & Debit Cards'),
          ...cards.map((m) => _buildCardTile(m, theme)).toList(),
          _buildAddMethodButton('Add Card'),
        ],
      ),

      // Save button at the bottom
      bottomSheet: SaveChangesButton(
        isEnabled: true,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment changes saved'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        label: 'Save Payment Methods',
        icon: Icons.credit_score_outlined,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAppWalletCard(Map<String, dynamic> wallet, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: const Icon(
            Icons.account_balance_wallet,
            color: Colors.black87,
          ),
        ),
        title: Text(
          wallet['type'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Balance: ${wallet['balance']}'),
        trailing: wallet['default'] == true
            ? Chip(
                label: const Text('Default'),
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              )
            : null,
      ),
    );
  }

  Widget _buildWalletCard(Map<String, dynamic> wallet, ThemeData theme) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: _buildIcon(wallet['type']),
        title: Text(
          wallet['type'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(wallet['email']),
        trailing: wallet['default'] == true
            ? Chip(
                label: const Text('Default'),
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              )
            : null,
      ),
    );
  }

  Widget _buildCardTile(Map<String, dynamic> card, ThemeData theme) {
    final isDefault = card['default'] == true;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: _buildIcon(card['type']),
        title: Row(
          children: [
            Expanded(
              child: Text(
                card['type'],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (isDefault)
              Chip(
                label: const Text('Default'),
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              ),
          ],
        ),
        subtitle: Text('${card['number']}\nExpires ${card['expiry']}'),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildAddMethodButton(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton.icon(
        onPressed: () {
          // TODO: Trigger add payment method flow
        },
        icon: const Icon(Icons.add),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildIcon(String type) {
    final lower = type.toLowerCase();
    IconData icon;

    if (lower.contains('visa'))
      icon = Icons.credit_card;
    else if (lower.contains('master'))
      icon = Icons.credit_card;
    else if (lower.contains('paypal'))
      icon = Icons.account_balance_wallet;
    else if (lower.contains('google'))
      icon = Icons.account_balance_wallet;
    else
      icon = Icons.payment;

    return CircleAvatar(
      backgroundColor: Colors.grey.shade100,
      child: Icon(icon, color: Colors.black87),
    );
  }
}
