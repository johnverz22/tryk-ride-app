import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // for formatting date

class CustomUserAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(75);

  @override
  Widget build(BuildContext context) {
    // final driver = Provider.of<DriverProvider>(context, listen: false).driver;
    final driver = null;
    final userName = driver?.fullName ?? 'Driver';
    final profilePhoto = driver?.profilePhotoUrl ?? '';
    final currentDate = DateFormat.yMMMMEEEEd().format(DateTime.now());

    // replace with statemanager
    bool isOnline = true;

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
            onPressed: () {},
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
              //todo: make a custom switch widget
              Switch(
                value: true,
                onChanged: null,
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