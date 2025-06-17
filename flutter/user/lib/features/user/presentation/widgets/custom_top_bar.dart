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
    final date = DateFormat.yMMMMd().format(DateTime.now());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Profile Section
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage(profileImageUrl),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hi, $userName 👋',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    )),
                Text(date,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    )),
              ],
            ),
          ],
        ),

        // Actions: Settings + Notifications
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                // TODO: Add settings navigation
              },
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white),
              onPressed: () {
                // TODO: Add notifications navigation
              },
            ),
          ],
        ),
      ],
    );
  }
}
