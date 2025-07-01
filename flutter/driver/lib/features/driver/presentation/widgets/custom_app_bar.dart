import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/driver_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart'; // <-- Add this
import '../../../../core/config/api_config.dart';

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

  Future<Position> _getCurrentPosition() async {
    LocationPermission permission;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> handleToggleOnline(bool value, BuildContext context) async {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);

    if (value) {
      try {
        Position position = await _getCurrentPosition();

        driverProvider.setOnlineStatus(true);

        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/driver/update-location'),
          headers: {
            'Authorization': 'Bearer ${driverProvider.token}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'is_online': driverProvider.isOnline,
          }),
        );
      } catch (e) {
        debugPrint('Failed to update location: $e');
      }
    } else {
      driverProvider.setOnlineStatus(false);

      try {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/driver/go-offline'),
          headers: {
            'Authorization': 'Bearer ${driverProvider.token}',
            'Content-Type': 'application/json',
          },
        );
      } catch (e) {
        debugPrint('Failed to go offline: $e');
      }
    }

    onToggleOnline(value);
  }

  @override
  Widget build(BuildContext context) {
    final driver = Provider.of<DriverProvider>(context, listen: false).driver;
    final userName = driver?.name ?? 'Driver';
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
                : const AssetImage('assets/images/default_avatar.png')
                      as ImageProvider,
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
              const SizedBox(width: 6),
              Switch(
                value: isOnline,
                thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Icon(Icons.check); // Online icon
                  }
                  return const Icon(Icons.close); // Offline icon
                }),
                onChanged: (value) => handleToggleOnline(value, context),
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
