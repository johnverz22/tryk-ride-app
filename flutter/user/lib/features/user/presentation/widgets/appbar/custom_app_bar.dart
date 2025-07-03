import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';

class CustomUserAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomUserAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (userState) {
        final user = userState.user;
        if (user == null) return const SizedBox.shrink();

        final isNetwork = user.profilePhotoUrl?.startsWith('http') ?? false;
        final imageProvider = isNetwork
            ? NetworkImage(user.profilePhotoUrl!)
            : const AssetImage('assets/images/profile.jpg') as ImageProvider;

        final theme = Theme.of(context);

        return AppBar(
          elevation: 0.5,
          backgroundColor: theme.colorScheme.primary,
          surfaceTintColor: theme.colorScheme.primary,
          toolbarHeight: preferredSize.height,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Profile Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: imageProvider,
                      backgroundColor: Colors.grey[200],
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Welcome,',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimary.withOpacity(0.8),
                          ),
                        ),
                        Text(
                          user.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Action Buttons
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_outlined),
                      onPressed: () {
                        // TODO: Handle notifications
                      },
                      tooltip: 'Notifications',
                      color: theme.colorScheme.onPrimary,
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () {
                        // TODO: Handle settings
                      },
                      tooltip: 'Settings',
                      color: theme.colorScheme.onPrimary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
