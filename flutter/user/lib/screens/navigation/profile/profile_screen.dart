// profile_screen.dart
import 'package:flutter/material.dart';
import 'logout_delete_account_dialogs.dart';
import 'personal_info_screen.dart';
import 'notifications_preferences_screen.dart';
import 'payment_methods_screen.dart';
import 'privacy_settings_screen.dart';
import 'language_settings_screen.dart';
import 'favorite_locations_screen.dart';
import 'preferred_drivers_screen.dart';
import 'vehicle_preferences_screen.dart';
import 'special_requirements_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage('assets/profile.jpg'),
              ),
              const SizedBox(height: 8),
              const Text('Alex Thompson', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Premium Member'),
              ),
              TextButton(onPressed: () {}, child: const Text('Edit Profile')),
            ],
          ),
          const Divider(height: 32),

          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.indigoAccent),
            title: const Text('Personal Information'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PersonalInfoScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: Colors.indigoAccent),
            title: const Text('Notifications Preferences'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPreferencesScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.payment_outlined, color: Colors.indigoAccent),
            title: const Text('Payment Methods'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: Colors.indigoAccent),
            title: const Text('Privacy Settings'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.indigoAccent),
            title: const Text('Language Settings'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()),
            ),
          ),
          const Divider(height: 32),

          ListTile(
            leading: const Icon(Icons.star_border, color: Colors.green),
            title: const Text('Favorite Locations'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoriteLocationsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people_alt_outlined, color: Colors.green),
            title: const Text('Preferred Drivers'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PreferredDriversScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.directions_car, color: Colors.green),
            title: const Text('Vehicle Preferences'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VehiclePreferencesScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.accessibility_new, color: Colors.green),
            title: const Text('Special Requirements'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SpecialRequirementsScreen()),
            ),
          ),

          const Divider(height: 32),

          ElevatedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => showLogoutDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            label: const Text('Logout'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            onPressed: () => showDeleteAccountDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            label: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}
