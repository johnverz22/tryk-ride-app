// special_requirements_screen.dart
import 'package:flutter/material.dart';

class SpecialRequirementsScreen extends StatefulWidget {
  const SpecialRequirementsScreen({super.key});

  @override
  State<SpecialRequirementsScreen> createState() => _SpecialRequirementsScreenState();
}

class _SpecialRequirementsScreenState extends State<SpecialRequirementsScreen> {
  final Map<String, bool> requirements = {
    'Wheelchair Accessible': false,
    'Child Seat': false,
    'Extra Assistance': false,
    'Pet Friendly': false,
  };

  final TextEditingController notesController = TextEditingController();

  void _toggleRequirement(String key) {
    setState(() {
      requirements[key] = !(requirements[key] ?? false);
    });
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Special Requirements')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Select any special requirements you may need', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...requirements.keys.map((req) => CheckboxListTile(
                  title: Text(req),
                  value: requirements[req],
                  onChanged: (_) => _toggleRequirement(req),
                )),
            const Divider(height: 32),
            const Text('Additional Notes'),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'I prefer a quiet ride and usually travel with a small dog.',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Save Requirements'),
            ),
          ],
        ),
      ),
    );
  }
}