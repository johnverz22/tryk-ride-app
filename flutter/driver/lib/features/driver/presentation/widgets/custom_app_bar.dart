import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // for formatting date
import '../providers/driver_provider.dart';

class CustomUserAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onNotificationTap;
  final bool isOnline;
  final ValueChanged<bool> onToggleOnline;

  const CustomUserAppBar({
    super.key,
    this.onNotificationTap,
    required this.isOnline,
    required this.onToggleOnline,
  });

  @override
  Size get preferredSize => const Size.fromHeight(75);

  @override
  Widget build(BuildContext context) {
    final driver = Provider.of<DriverProvider>(context, listen: false).driver;
    final userName = driver?.fullName ?? 'Driver';
    final profilePhoto = driver?.profilePhotoUrl ?? '';
    final currentDate = DateFormat.yMMMMEEEEd().format(DateTime.now());

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pinkAccent, Colors.deepPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      toolbarHeight: preferredSize.height,
      titleSpacing: 16,
      title: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: profilePhoto.isNotEmpty
                ? NetworkImage(profilePhoto)
                : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Hi, $userName 👋',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  currentDate,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: onNotificationTap ?? () {},
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              Icon(
                isOnline ? Icons.circle : Icons.circle_outlined,
                size: 14,
                color: isOnline ? Colors.greenAccent : Colors.grey[400],
              ),
              const SizedBox(width: 6),
              Switch(
                value: isOnline,
                onChanged: onToggleOnline,
                activeColor: Colors.greenAccent,
                inactiveThumbColor: Colors.grey,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
