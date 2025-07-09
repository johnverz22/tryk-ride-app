import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:user/features/user/data/models/payment_method_model.dart';
import 'package:user/features/user/presentation/pages/screens/navigation/profile/payment_methods_screen/add_card_screen.dart';
import 'package:user/features/user/presentation/providers/payment_info_provider.dart';
import 'package:user/features/user/presentation/widgets/profile_screen/save_changes_button.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final paymentInfo = ref.watch(paymentInfoProvider);

    final isLoading = paymentInfo.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : paymentInfo.when(
              data: (info) {
                final wallet = info.wallet;
                final digitalWallets = info.paymentMethods
                    .where((m) => m.type == 'wallet')
                    .toList();
                final cards = info.paymentMethods
                    .where((m) => m.type == 'card')
                    .toList();

                final hasGcash = digitalWallets.any(
                  (m) => m.provider.toLowerCase().contains('gcash'),
                );
                final hasMaya = digitalWallets.any(
                  (m) => m.provider.toLowerCase().contains('maya'),
                );

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(paymentInfoProvider.notifier)
                        .refreshPaymentInfo();
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                    children: [
                      ...[
                        _buildSectionTitle('Tryk Wallet'),
                        _buildAppWalletCard(theme, wallet, context),
                        const SizedBox(height: 24),
                      ],
                      _buildSectionTitle('Digital Wallets'),
                      if (!hasGcash)
                        _buildConnectWalletCard(
                          name: 'GCash',
                          logoAsset: 'assets/images/logo/gcash.png',
                          onConnect: () =>
                              _showConnectSnackbar(context, 'GCash'),
                        ),
                      if (!hasMaya)
                        _buildConnectWalletCard(
                          name: 'Maya',
                          logoAsset: 'assets/images/logo/maya.png',
                          onConnect: () =>
                              _showConnectSnackbar(context, 'Maya'),
                        ),
                      ...digitalWallets.map(
                        (m) => _buildWalletCard(m, theme, context, ref),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Credit & Debit Cards'),
                      ...cards.map(
                        (m) => _buildCardTile(m, theme, context, ref),
                      ),
                      _buildAddMethodButton('Add Card', context, ref),
                    ],
                  ),
                );
              },
              error: (e, st) => Center(child: Text('Error: $e')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
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

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildAppWalletCard(
    ThemeData theme,
    dynamic wallet,
    BuildContext context,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withAlpha(20),
          child: const Icon(
            Icons.account_balance_wallet,
            color: Colors.black87,
          ),
        ),
        title: const Text(
          'Tryk Wallet',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Balance: ${wallet.formattedBalance}'),
        trailing: TextButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Top Up action triggered')),
            );
          },
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Top Up'),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard(
    PaymentMethod method,
    ThemeData theme,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: _buildIcon(method.provider),
        title: Text(
          method.provider,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(method.label ?? '—'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () async {
            final confirmed = await _showConfirmationDialog(context);
            if (confirmed) {
              await _deletePaymentMethod(method.id, context);
              ref.read(paymentInfoProvider.notifier).refreshPaymentInfo();
            }
          },
        ),
      ),
    );
  }

  Widget _buildCardTile(
    PaymentMethod card,
    ThemeData theme,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: _buildIcon(card.provider),
        subtitle: Text('**** **** **** ${card.lastFour}\n${card.label ?? ''}'),
        title: Text(
          card.provider,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'remove') {
              _deletePaymentMethod(card.id, context).then((_) {
                ref.read(paymentInfoProvider.notifier).refreshPaymentInfo();
              });
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'remove', child: Text('Remove')),
          ],
          icon: const Icon(Icons.more_vert),
        ),
      ),
    );
  }

  Widget _buildAddMethodButton(
    String label,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCardScreen()),
          ).then((value) {
            if (value == true) {
              ref.read(paymentInfoProvider.notifier).refreshPaymentInfo();
            }
          });
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

  Widget _buildIcon(String provider) {
    final lower = provider.toLowerCase();
    IconData icon;
    if (lower.contains('visa') || lower.contains('master')) {
      icon = Icons.credit_card;
    } else if (lower.contains('gcash') || lower.contains('maya')) {
      icon = Icons.account_balance_wallet;
    } else {
      icon = Icons.payment;
    }
    return CircleAvatar(
      backgroundColor: Colors.grey.shade100,
      child: Icon(icon, color: Colors.black87),
    );
  }

  Widget _buildConnectWalletCard({
    required String name,
    required String logoAsset,
    required VoidCallback onConnect,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade100,
          radius: 24,
          backgroundImage: AssetImage(logoAsset),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Not Connected'),
        trailing: ElevatedButton(
          onPressed: onConnect,
          child: const Text('Connect'),
        ),
      ),
    );
  }

  Future<void> _deletePaymentMethod(String id, BuildContext context) async {
    final baseUrl = dotenv.env['BASE_URL'];
    final token = await const FlutterSecureStorage().read(key: 'token');
    if (baseUrl == null || token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/payment-methods/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment method removed')));
      } else {
        throw Exception('Failed to delete');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove Payment Method'),
            content: const Text('Are you sure you want to remove this method?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showConnectSnackbar(BuildContext context, String method) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$method connect pressed')));
  }
}
