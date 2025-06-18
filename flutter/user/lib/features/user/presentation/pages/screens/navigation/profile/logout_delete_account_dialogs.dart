import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../../core/services/auth_service.dart';
import '../../../../providers/user_provider.dart';
import '../../auth/auth_screen.dart';

Future<void> showLogoutDialog(BuildContext context) async {
  // Get provider and services BEFORE the dialog closes
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final authService = AuthService();

  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout from your account?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop(); // Close the dialog

              await authService.logout(context);
              await userProvider.logout();

              // Use outer `context`, which is still valid
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      );
    },
  );
}

Future<void> showDeleteAccountDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // Add delete account logic here
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
}
