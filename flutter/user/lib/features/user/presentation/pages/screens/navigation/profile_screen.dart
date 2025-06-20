import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';
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
    final user = Provider.of<UserProvider>(context).user;

    final name = user?.fullName ?? 'Guest';
    final email = user?.email ?? '';
    final photoUrl = user?.profilePhotoUrl;

    return Scaffold(
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProfileHeader(context, name, email, photoUrl),
                const SizedBox(height: 32),

                _sectionCard(
                  title: 'Account Settings',
                  items: [
                    _buildNavTile(context, Icons.person_outline, 'Personal Information', const PersonalInfoScreen()),
                    _buildNavTile(context, Icons.notifications_outlined, 'Notifications Preferences', const NotificationsPreferencesScreen()),
                    _buildNavTile(context, Icons.payment_outlined, 'Payment Methods', const PaymentMethodsScreen()),
                    _buildNavTile(context, Icons.lock_outline, 'Privacy Settings', const PrivacySettingsScreen()),
                    _buildNavTile(context, Icons.language, 'Language Settings', const LanguageSettingsScreen()),
                  ],
                ),

                const SizedBox(height: 24),
                _sectionCard(
                  title: 'Trip Preferences',
                  items: [
                    _buildNavTile(context, Icons.star_border, 'Favorite Locations', const FavoriteLocationsScreen()),
                    _buildNavTile(context, Icons.people_alt_outlined, 'Preferred Drivers', const PreferredDriversScreen()),
                    _buildNavTile(context, Icons.directions_car, 'Vehicle Preferences', const VehiclePreferencesScreen()),
                    _buildNavTile(context, Icons.accessibility_new, 'Special Requirements', const SpecialRequirementsScreen()),
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

  Widget _buildProfileHeader(BuildContext context, String name, String email, String? photoUrl) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : const AssetImage('assets/profile.jpg') as ImageProvider,
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Premium Member',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9C6E00),
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

  Widget _buildNavTile(BuildContext context, IconData icon, String title, Widget screen, {Color? iconColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
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
