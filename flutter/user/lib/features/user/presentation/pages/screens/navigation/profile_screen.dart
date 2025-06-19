import 'package:flutter/material.dart';
import 'profile/logout_delete_account_dialogs.dart';
import 'profile/personal_info_screen.dart';
import 'profile/notifications_preferences_screen.dart';
import 'profile/payment_methods_screen.dart';
import 'profile/privacy_settings_screen.dart';
import 'profile/language_settings_screen.dart';
import 'profile/favorite_locations_screen.dart';
import 'profile/preferred_drivers_screen.dart';
import 'profile/vehicle_preferences_screen.dart';
import 'profile/special_requirements_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          _buildProfileHeader(context),
          const SizedBox(height: 24),

          _sectionHeader('Account Settings'),
          _buildNavTile(context, Icons.person_outline, 'Personal Information', const PersonalInfoScreen()),
          _buildNavTile(context, Icons.notifications_outlined, 'Notifications Preferences', const NotificationsPreferencesScreen()),
          _buildNavTile(context, Icons.payment_outlined, 'Payment Methods', const PaymentMethodsScreen()),
          _buildNavTile(context, Icons.lock_outline, 'Privacy Settings', const PrivacySettingsScreen()),
          _buildNavTile(context, Icons.language, 'Language Settings', const LanguageSettingsScreen()),

          const SizedBox(height: 32),
          _sectionHeader('Trip Preferences'),
          _buildNavTile(context, Icons.star_border, 'Favorite Locations', const FavoriteLocationsScreen(), iconColor: Colors.green),
          _buildNavTile(context, Icons.people_alt_outlined, 'Preferred Drivers', const PreferredDriversScreen(), iconColor: Colors.green),
          _buildNavTile(context, Icons.directions_car, 'Vehicle Preferences', const VehiclePreferencesScreen(), iconColor: Colors.green),
          _buildNavTile(context, Icons.accessibility_new, 'Special Requirements', const SpecialRequirementsScreen(), iconColor: Colors.green),

          const SizedBox(height: 32),
          _sectionHeader('Security'),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            onPressed: () => showLogoutDialog(context),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever),
            onPressed: () => showDeleteAccountDialog(context),
            label: const Text('Delete Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 44,
          backgroundImage: AssetImage('assets/profile.jpg'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Alex Thompson',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Premium Member',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('Edit Profile'),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
    );
  }

  Widget _buildNavTile(BuildContext context, IconData icon, String title, Widget screen, {Color? iconColor}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: iconColor ?? Colors.indigoAccent),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
    );
  }
}
