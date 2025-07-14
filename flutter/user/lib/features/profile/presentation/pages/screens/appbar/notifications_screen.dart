import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        leading: const BackButton(color: Colors.white),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5, // Replace with dynamic count from provider/API
        separatorBuilder: (_, __) => const Divider(height: 24),
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(
              Icons.notifications,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              'Your ride has been completed',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Thank you for riding with us! Tap to rate your trip.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            onTap: () {}, // Navigate to ride details or feedback screen
            trailing: Text(
              '2h ago',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}
