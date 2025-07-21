// file: lib/features/ride/presentation/widgets/ride_booking_screen/payment_method_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// IMPORTANT: Make sure these providers and screens are correctly imported from your project.
import 'package:user/features/profile/presentation/providers/payment_info_provider.dart';
import 'package:user/features/profile/presentation/pages/screens/navigation/menu/payment_methods_screen/add_card_screen.dart';

// You should have this entity defined and accessible from your providers.
// This is here as a placeholder for what the provider should return.
// class CardEntity {
//   final String id;
//   final String provider;
//   final String lastFour;
//   CardEntity({required this.id, required this.provider, required this.lastFour});
// }

/// A compact widget to display the selected payment method. Tapping it opens a selection sheet.
class CompactPaymentMethodDisplay extends StatelessWidget {
  final String selectedMethodLabel;
  final IconData selectedMethodIcon;
  final VoidCallback onChange;

  const CompactPaymentMethodDisplay({
    super.key,
    required this.selectedMethodLabel,
    required this.selectedMethodIcon,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onChange,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              selectedMethodIcon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedMethodLabel,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              "Change",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// A professional, sectioned, and SCROLLABLE modal bottom sheet for selecting a payment method.
class PaymentSelectionSheet extends ConsumerWidget {
  final String selectedMethodId;
  final void Function(String) onSelect;

  const PaymentSelectionSheet({
    required this.selectedMethodId,
    required this.onSelect,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use your actual providers to fetch live data
    final wallet = ref.watch(walletProvider);
    final cards = ref.watch(cardsProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- FIXED HEADER ---
          // This part will NOT scroll.
          Text(
            "Select Payment",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // --- SCROLLABLE LIST SECTION ---
          // This Flexible + ListView combination solves the overflow error.
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                // --- Tryk Wallet Section ---
                _buildSectionTitle('Tryk Wallet', theme),
                if (wallet != null)
                  _buildPaymentTile(
                    context: context,
                    id: 'Wallet',
                    icon: Icons.account_balance_wallet,
                    label: 'Wallet',
                    subtitle: 'Balance: ${wallet.formattedBalance}',
                  ),

                const SizedBox(height: 16),

                // --- Digital Wallets Section ---
                _buildSectionTitle('Digital Wallets', theme),
                _buildPaymentTile(
                  context: context,
                  id: 'gcash',
                  icon: Icons.phone_iphone,
                  label: 'GCash',
                ),
                _buildPaymentTile(
                  context: context,
                  id: 'maya',
                  icon: Icons.shield_rounded,
                  label: 'Maya',
                ),

                const SizedBox(height: 16),

                // --- Credit & Debit Cards Section ---
                _buildSectionTitle('Credit & Debit Cards', theme),
                if (cards.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    child: Text(
                      "No cards added yet.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...cards.map(
                    (card) => _buildPaymentTile(
                      context: context,
                      id: card.id,
                      icon: Icons.credit_card,
                      label: '${card.provider} •••• ${card.lastFour}',
                    ),
                  ),

                // Add Card Button
                _buildAddCardButton(context, ref),

                const SizedBox(height: 16),

                // --- Cash Section ---
                _buildSectionTitle('Cash upon Arrival', theme),
                _buildPaymentTile(
                  context: context,
                  id: 'Cash',
                  icon: Icons.money,
                  label: 'Cash',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildAddCardButton(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
      title: Text(
        "Add a new card",
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
      onTap: () {
        Navigator.pop(context); // Pop the current modal sheet
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddCardScreen()),
        ).then((cardWasAdded) {
          if (cardWasAdded == true) {
            ref.read(paymentInfoProvider.notifier).refreshPaymentInfo();
          }
        });
      },
    );
  }

  Widget _buildPaymentTile({
    required BuildContext context,
    required String id,
    required IconData icon,
    required String label,
    String? subtitle,
  }) {
    final bool isSelected = selectedMethodId == id;
    final theme = Theme.of(context);
    return ListTile(
      onTap: () {
        onSelect(id);
        Navigator.pop(context);
      },
      leading: Icon(
        icon,
        color: isSelected ? theme.colorScheme.primary : Colors.grey[700],
        size: 28,
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: theme.textTheme.bodyMedium)
          : null,
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 24)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
