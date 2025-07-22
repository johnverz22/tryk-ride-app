import 'package:flutter/material.dart';
import '../../../widgets/widgets.dart'; // Adjust path to your SaveChangesButton

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool shareStatus = true;
  bool locationServices = true;
  bool dataCollection = false;
  String contactPermission = 'Only Friends';

  final defaultValues = const {
    'shareStatus': true,
    'locationServices': true,
    'dataCollection': false,
    'contactPermission': 'Only Friends',
  };

  bool get _isModified =>
      shareStatus != defaultValues['shareStatus'] ||
      locationServices != defaultValues['locationServices'] ||
      dataCollection != defaultValues['dataCollection'] ||
      contactPermission != defaultValues['contactPermission'];

  static const contactOptions = ['Everyone', 'Only Friends', 'Nobody'];

  void _resetToDefaults() {
    setState(() {
      shareStatus = defaultValues['shareStatus'] as bool;
      locationServices = defaultValues['locationServices'] as bool;
      dataCollection = defaultValues['dataCollection'] as bool;
      contactPermission = defaultValues['contactPermission'] as String;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 130),
        children: [
          _sectionHeader(
            title: 'Activity Preferences',
            action: TextButton(
              onPressed: _isModified ? _resetToDefaults : null,
              child: const Text('Reset to Default'),
            ),
          ),
          _settingCard([
            _toggle(
              title: 'Share Trip Status',
              subtitle: 'Allow others to view your trip progress.',
              value: shareStatus,
              icon: Icons.share_outlined,
              onChanged: (v) => setState(() => shareStatus = v),
            ),
            _toggle(
              title: 'Location Services',
              subtitle: 'Enable location-based features for better accuracy.',
              value: locationServices,
              icon: Icons.location_on_outlined,
              onChanged: (v) => setState(() => locationServices = v),
            ),
            _toggle(
              title: 'Allow Data Collection',
              subtitle: 'Help us improve by sharing anonymous usage data.',
              value: dataCollection,
              icon: Icons.bar_chart_outlined,
              onChanged: (v) => setState(() => dataCollection = v),
            ),
          ]),

          const SizedBox(height: 32),
          _sectionHeader(title: 'Who Can Contact You'),
          _settingCard(contactOptions.map((value) => _radio(value)).toList()),
        ],
      ),

      bottomSheet: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: SaveChangesButton(
          isEnabled: _isModified,
          onPressed: () {
            FocusScope.of(context).unfocus();
            _saveChanges(context);
          },
          label: 'Save Privacy Settings',
          icon: Icons.privacy_tip_outlined,
        ),
      ),
    );
  }

  void _saveChanges(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('Privacy settings saved')),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green.shade600,
      ),
    );

    setState(() {}); // Reset tracking
  }

  Widget _sectionHeader({required String title, Widget? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _settingCard(List<Widget> children) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(top: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: List.generate(children.length * 2 - 1, (i) {
          return i.isEven
              ? children[i ~/ 2]
              : const Divider(height: 0, thickness: 1);
        }),
      ),
    );
  }

  Widget _toggle({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? subtitle,
    IconData? icon,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: SwitchListTile.adaptive(
        key: ValueKey(value),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        value: value,
        onChanged: onChanged,
        secondary: icon != null ? Icon(icon) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _radio(String value) {
    return RadioListTile<String>(
      title: Text(value),
      value: value,
      groupValue: contactPermission,
      onChanged: (val) => setState(() => contactPermission = val!),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
