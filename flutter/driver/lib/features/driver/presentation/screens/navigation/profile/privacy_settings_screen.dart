import 'package:flutter/material.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool shareStatus = true;
  bool locationServices = true;
  bool dataCollection = false;
  String contactPermission = 'Friends';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _toggle('Share Trip Status', shareStatus, (v) => setState(() => shareStatus = v)),
            _toggle('Location Services', locationServices, (v) => setState(() => locationServices = v)),
            _toggle('Data Collection', dataCollection, (v) => setState(() => dataCollection = v)),
            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text('Who Can Contact You', style: TextStyle(fontWeight: FontWeight.bold))),
            _radio('Everyone'),
            _radio('Only Friends'),
            _radio('Nobody'),
            const Spacer(),
            ElevatedButton(onPressed: () {}, child: const Text('Save Privacy Settings'))
          ],
        ),
      ),
    );
  }

  Widget _toggle(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(title: Text(title), value: value, onChanged: onChanged);
  }

  Widget _radio(String value) {
    return RadioListTile(
      title: Text(value),
      value: value,
      groupValue: contactPermission,
      onChanged: (val) => setState(() => contactPermission = val as String),
    );
  }
}
