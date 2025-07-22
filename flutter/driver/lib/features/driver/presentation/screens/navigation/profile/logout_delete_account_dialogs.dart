import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/services/auth_service.dart';
import '../../../providers/driver_provider.dart';

Future<void> showLogoutDialog(BuildContext context, WidgetRef ref) async {
  final authService = ref.read(authServiceProvider);

  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout from your account?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop(); // Close the dialog first

              try {
                await authService.logout();

                // Clear user state so GoRouter redirect logic works
                await ref.read(driverProvider.notifier).setDriver(null, null);

                if (!context.mounted) return;

                // Redirect using GoRouter (recommended)
                context.go('/auth');
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
              }
            },
            child: const Text('Logout'),
          ),
        ],
      );
    },
  );
}

Future<void> showDeleteAccountDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(dialogContext).pop();

              // TODO: Replace with actual delete account logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Account deletion not implemented."),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
}
