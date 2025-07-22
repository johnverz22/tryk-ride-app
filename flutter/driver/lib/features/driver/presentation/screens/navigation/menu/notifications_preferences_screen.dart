import 'package:flutter/material.dart';
import '../../../widgets/widgets.dart'; // Make sure this includes SaveChangesButton

class NotificationsPreferencesScreen extends StatefulWidget {
  const NotificationsPreferencesScreen({super.key});

  @override
  State<NotificationsPreferencesScreen> createState() =>
      _NotificationsPreferencesScreenState();
}

class _NotificationsPreferencesScreenState
    extends State<NotificationsPreferencesScreen> {
  bool push = true;
  bool email = true;
  bool sms = false;
  bool marketing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _buildSwitchCard(
            icon: Icons.notifications_active_outlined,
            title: 'Push Notifications',
            subtitle: 'Receive alerts directly on your device.',
            value: push,
            onChanged: (val) => setState(() => push = val),
          ),
          _buildSwitchCard(
            icon: Icons.email_outlined,
            title: 'Email Notifications',
            subtitle: 'Get updates and receipts via email.',
            value: email,
            onChanged: (val) => setState(() => email = val),
          ),
          _buildSwitchCard(
            icon: Icons.sms_outlined,
            title: 'SMS Notifications',
            subtitle: 'Get important updates via text messages.',
            value: sms,
            onChanged: (val) => setState(() => sms = val),
          ),
          _buildSwitchCard(
            icon: Icons.campaign_outlined,
            title: 'Marketing Communications',
            subtitle: 'Receive special offers and promotions.',
            value: marketing,
            onChanged: (val) => setState(() => marketing = val),
          ),
        ],
      ),
      bottomSheet: SaveChangesButton(
        onPressed: _handleSave,
        label: 'Save Preferences',
        icon: Icons.save_outlined,
      ),
    );
  }

  void _handleSave() {
    // TODO: Save to backend or state
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferences saved successfully'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveTrackColor: Colors.grey.shade400,
        ),
      ),
    );
  }
}
