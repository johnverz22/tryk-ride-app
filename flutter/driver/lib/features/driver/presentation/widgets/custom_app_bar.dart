import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/driver_provider.dart';

class CustomUserAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final void Function()? onNotificationTap;

  const CustomUserAppBar({super.key, this.onNotificationTap});

  @override
  Size get preferredSize => const Size.fromHeight(90);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDriverState = ref.watch(driverProvider);

    return asyncDriverState.maybeWhen(
      data: (driverState) {
        final userName = driverState.driver?.name ?? 'Driver';
        final profilePhoto = driverState.driver?.profilePhotoUrl ?? '';
        final isOnline = driverState.isOnline;
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
              Switch(
                value: isOnline,
                onChanged: (value) =>
                    ref.read(driverProvider.notifier).toggleOnline(value),
                thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Icon(Icons.check);
                  }
                  return const Icon(Icons.close);
                }),
                activeColor: Colors.greenAccent,
                inactiveThumbColor: Colors.grey,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        );
      },
      loading: () => AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: preferredSize.height,
        title: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
      orElse: () => AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        title: const Text('Error loading driver'),
      ),
    );
  }
}
