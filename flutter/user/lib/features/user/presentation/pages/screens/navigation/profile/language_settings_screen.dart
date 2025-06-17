import 'package:flutter/material.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String currentLanguage = 'English';
  final languages = ['English', 'Español', 'Français', 'Deutsch', '中文'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Language Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var lang in languages)
              RadioListTile(
                title: Text(lang),
                value: lang,
                groupValue: currentLanguage,
                onChanged: (val) => setState(() => currentLanguage = val as String),
                secondary: currentLanguage == lang ? const Icon(Icons.check, color: Colors.green) : null,
              ),
            const Spacer(),
            ElevatedButton(onPressed: () {}, child: const Text('Save Language')),
          ],
        ),
      ),
    );
  }
}
