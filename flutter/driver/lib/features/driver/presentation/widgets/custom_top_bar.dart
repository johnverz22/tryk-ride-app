import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomTopBar extends StatelessWidget {
  final String userName;
  final String profileImageUrl;

  const CustomTopBar({
    super.key,
    required this.userName,
    required this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Profile Section
        GestureDetector(
          onTap: () {
            // TODO: Navigate to driver profile screen
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, $userName 👋',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Action Icons
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              tooltip: 'Settings',
              onPressed: () {
                // TODO: Navigate to settings screen
              },
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white),
              tooltip: 'Notifications',
              onPressed: () {
                // TODO: Navigate to notifications
              },
            ),
          ],
        ),
      ],
    );
  }
}
