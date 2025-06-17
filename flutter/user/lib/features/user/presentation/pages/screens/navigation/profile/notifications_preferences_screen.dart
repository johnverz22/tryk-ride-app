import 'package:flutter/material.dart';

class NotificationsPreferencesScreen extends StatefulWidget {
  const NotificationsPreferencesScreen({super.key});

  @override
  State<NotificationsPreferencesScreen> createState() => _NotificationsPreferencesScreenState();
}

class _NotificationsPreferencesScreenState extends State<NotificationsPreferencesScreen> {
  bool push = true;
  bool email = true;
  bool sms = false;
  bool marketing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _switchTile('Push Notifications', 'Receive alerts on your device', push, (val) => setState(() => push = val)),
            _switchTile('Email Notifications', 'Receive trip updates via email', email, (val) => setState(() => email = val)),
            _switchTile('SMS Notifications', 'Receive text messages for important updates', sms, (val) => setState(() => sms = val)),
            _switchTile('Marketing Communications', 'Receive offers and promotions', marketing, (val) => setState(() => marketing = val)),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // Save logic here
              },
              child: const Text('Save Preferences'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}
