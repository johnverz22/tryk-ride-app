import 'package:flutter/material.dart';

class DrivingSetupScreen extends StatefulWidget {
  const DrivingSetupScreen({super.key});

  @override
  State<DrivingSetupScreen> createState() => _DrivingSetupScreenState();
}

class _DrivingSetupScreenState extends State<DrivingSetupScreen> {
  double pickupRadius = 10;
  bool allowSmoking = false;
  bool allowPets = true;
  TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 20, minute: 0);

  bool canTransportWheelchair = false;
  bool hasChildSeat = false;
  bool petFriendly = false;
  bool assistanceAvailable = false;

  Future<void> _pickTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
    );
    if (picked != null) {
      setState(() {
        isStart ? startTime = picked : endTime = picked;
      });
    }
  }

  void _savePreferences() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferences saved successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driving Preferences'),
        centerTitle: true,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _sectionCard(
                title: 'Pickup Radius',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pickupRadius.toStringAsFixed(0)} km',
                      style: textTheme.titleMedium,
                    ),
                    Slider(
                      value: pickupRadius,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      label: '${pickupRadius.toStringAsFixed(0)} km',
                      onChanged: (value) => setState(() => pickupRadius = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'Working Hours',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _timeButton(
                      label: 'Start: ${startTime.format(context)}',
                      icon: Icons.login,
                      onPressed: () => _pickTime(true),
                    ),
                    _timeButton(
                      label: 'End: ${endTime.format(context)}',
                      icon: Icons.logout,
                      onPressed: () => _pickTime(false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'General Preferences',
                child: Column(
                  children: [
                    _switchTile(
                      title: 'Allow Smoking in Car',
                      icon: Icons.smoking_rooms,
                      value: allowSmoking,
                      onChanged: (val) => setState(() => allowSmoking = val),
                    ),
                    _switchTile(
                      title: 'Pet-Friendly Vehicle',
                      icon: Icons.pets,
                      value: allowPets,
                      onChanged: (val) => setState(() => allowPets = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'Special Accommodations',
                child: Column(
                  children: [
                    _switchTile(
                      title: 'Wheelchair Accessible',
                      icon: Icons.accessible,
                      value: canTransportWheelchair,
                      onChanged: (val) => setState(() => canTransportWheelchair = val),
                    ),
                    _switchTile(
                      title: 'Child Seat Available',
                      icon: Icons.child_friendly,
                      value: hasChildSeat,
                      onChanged: (val) => setState(() => hasChildSeat = val),
                    ),
                    _switchTile(
                      title: 'Comfortable with Pets',
                      icon: Icons.pets_outlined,
                      value: petFriendly,
                      onChanged: (val) => setState(() => petFriendly = val),
                    ),
                    _switchTile(
                      title: 'Able to Assist Passengers',
                      icon: Icons.volunteer_activism,
                      value: assistanceAvailable,
                      onChanged: (val) => setState(() => assistanceAvailable = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Preferences'),
                  onPressed: _savePreferences,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _timeButton({required String label, required IconData icon, required VoidCallback onPressed}) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        textStyle: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      secondary: Icon(icon, color: theme.colorScheme.primary),
      value: value,
      onChanged: onChanged,
      activeColor: theme.colorScheme.primary,
      inactiveThumbColor: Colors.grey.shade400,
      inactiveTrackColor: Colors.grey.shade300,
    );
  }
}
