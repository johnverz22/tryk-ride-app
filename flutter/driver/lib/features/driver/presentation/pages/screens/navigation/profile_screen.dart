import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/driver_provider.dart';
import 'profile/logout_delete_account_dialogs.dart';
import 'profile/personal_info_screen.dart';
import 'profile/notifications_preferences_screen.dart';
import 'profile/privacy_settings_screen.dart';
import 'profile/language_settings_screen.dart';
import 'profile/vehicle_details_screen.dart';
import 'profile/driving_setup_screen.dart';
import 'profile/driver_id_verification_screen.dart';
import 'profile/earnings_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final driver = Provider.of<DriverProvider>(context).driver;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0.5,
        title: const Text(
          'Driver Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: driver == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProfileHeader(context, driver),
                const SizedBox(height: 32),
                _sectionCard(
                  title: 'Driver Account',
                  items: [
                    _buildNavTile(context, Icons.person_outline, 'Personal Information', const PersonalInfoScreen()),
                    _buildNavTile(context, Icons.verified_user, 'Driver ID Verification', const DriverIdVerificationScreen()),
                    _buildNavTile(context, Icons.notifications_outlined, 'Notification Preferences', const NotificationsPreferencesScreen()),
                    _buildNavTile(context, Icons.payment, 'Payment & Earnings Settings', const EarningsSettingsScreen()),
                    _buildNavTile(context, Icons.lock_outline, 'Privacy Settings', const PrivacySettingsScreen()),
                    _buildNavTile(context, Icons.language, 'Language Settings', const LanguageSettingsScreen()),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionCard(
                  title: 'Driving Preferences',
                  items: [
                    _buildNavTile(context, Icons.directions_car, 'Vehicle Details', const VehicleDetailsScreen()),
                    _buildNavTile(context, Icons.accessibility_new, 'Special Rider Requirements', const DrivingSetupScreen()),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionCard(
                  title: 'Security',
                  items: [
                    _buildActionButton(
                      context,
                      label: 'Logout',
                      icon: Icons.logout,
                      color: theme.colorScheme.primary,
                      onPressed: () => showLogoutDialog(context),
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      context,
                      label: 'Delete Account',
                      icon: Icons.delete_forever,
                      color: Colors.red,
                      onPressed: () => showDeleteAccountDialog(context),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, driver) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundImage: driver.profilePhotoUrl != null
                ? NetworkImage(driver.profilePhotoUrl!)
                : const AssetImage('assets/driver_avatar.jpg') as ImageProvider,
          ),
          const SizedBox(height: 12),
          Text(
            driver.fullName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: driver.isVerified ? Colors.green.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              driver.isVerified ? 'Verified Driver' : 'Unverified Driver',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: driver.isVerified ? Colors.green.shade800 : Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _sectionCard({required String title, required List<Widget> items}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            const Divider(),
            ...items.expand((widget) => [widget, const Divider(height: 0)]).toList()..removeLast(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile(BuildContext context, IconData icon, String title, Widget screen) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required String label, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
