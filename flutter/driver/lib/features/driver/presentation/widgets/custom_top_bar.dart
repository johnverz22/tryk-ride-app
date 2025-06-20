import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomTopBar extends StatelessWidget {
  final String userName;
  final String profileImageUrl;
  final bool isOnline;
  final ValueChanged<bool> onToggleOnline;

  const CustomTopBar({
    super.key,
    required this.userName,
    required this.profileImageUrl,
    required this.isOnline,
    required this.onToggleOnline,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE, MMM d').format(DateTime.now());
    final white70 = Colors.white70;
    final white = Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // 👤 Profile & Greeting
          Expanded(
            child: GestureDetector(
              onTap: () {
                // TODO: Navigate to profile screen
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                    onBackgroundImageError: (_, __) {
                      // optionally handle image load error
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            'Hi, $userName 👋',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            date,
                            style: TextStyle(
                              fontSize: 13,
                              color: white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔔 Notifications + Online Toggle
          Row(
            children: [
              // 🔔 Notification Button
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                tooltip: 'Notifications',
                onPressed: () {
                  // TODO: Navigate to notifications
                },
              ),

              const SizedBox(width: 4),

              // 🟢 Online Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOnline ? Icons.circle : Icons.circle_outlined,
                      size: 12,
                      color: isOnline ? Colors.greenAccent : Colors.grey.shade400,
                      semanticLabel: isOnline ? 'Online status active' : 'Online status inactive',
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    Semantics(
                      container: true,
                      label: 'Toggle online status',
                      child: Switch(
                        value: isOnline,
                        onChanged: onToggleOnline,
                        activeColor: Colors.greenAccent,
                        inactiveThumbColor: Colors.grey,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        splashRadius: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
