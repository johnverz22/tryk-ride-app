import 'package:flutter/material.dart';

class EarningsSettingsScreen extends StatefulWidget {
  const EarningsSettingsScreen({super.key});

  @override
  State<EarningsSettingsScreen> createState() => _EarningsSettingsScreenState();
}

class _EarningsSettingsScreenState extends State<EarningsSettingsScreen> {
  bool autoPayoutEnabled = true;
  String selectedMethod = 'Bank Transfer';
  String payoutFrequency = 'Weekly';

  final List<String> methods = ['Bank Transfer', 'PayPal', 'CashApp'];
  final List<String> frequencies = ['Weekly', 'Monthly'];

  void _saveSettings() {
    // TODO: Save settings to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Earnings settings updated.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Automatic Payouts'),
              subtitle: const Text('Enable to receive earnings automatically'),
              value: autoPayoutEnabled,
              onChanged: (value) {
                setState(() => autoPayoutEnabled = value);
              },
            ),
            const SizedBox(height: 24),
            Text('Payout Method', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedMethod,
              items: methods
                  .map((method) => DropdownMenuItem(value: method, child: Text(method)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => selectedMethod = value);
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            Text('Payout Frequency', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: payoutFrequency,
              items: frequencies
                  .map((freq) => DropdownMenuItem(value: freq, child: Text(freq)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => payoutFrequency = value);
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('Save Settings'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
