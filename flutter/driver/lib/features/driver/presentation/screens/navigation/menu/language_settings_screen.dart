import 'package:flutter/material.dart';
import '../../../widgets/widgets.dart'; // Adjust to where SaveChangesButton is

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String currentLanguage = 'English';
  String selectedLanguage = 'English';

  final languages = ['English', 'Español', 'Français', 'Deutsch', '中文'];

  bool get _isModified => currentLanguage != selectedLanguage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Language Settings')),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
        children: [
          const Text(
            'Choose Your Preferred Language',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: List.generate(languages.length * 2 - 1, (i) {
                if (i.isOdd) return const Divider(height: 0, thickness: 1);
                final lang = languages[i ~/ 2];
                return RadioListTile<String>(
                  title: Text(lang),
                  value: lang,
                  groupValue: selectedLanguage,
                  onChanged: (val) => setState(() => selectedLanguage = val!),
                  secondary: selectedLanguage == lang
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.language_outlined),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }),
            ),
          ),
        ],
      ),

      bottomSheet: SaveChangesButton(
        isEnabled: _isModified,
        onPressed: () {
          FocusScope.of(context).unfocus();
          _saveLanguage(context);
        },
        label: 'Save Language',
        icon: Icons.language_outlined,
      ),
    );
  }

  void _saveLanguage(BuildContext context) {
    setState(() {
      currentLanguage = selectedLanguage;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('Language preference saved')),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green.shade600,
      ),
    );
  }
}
