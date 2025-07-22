import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/driver_provider.dart';
import '../../screens/appbar/notifications_screen.dart';

class CustomUserAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final void Function()? onNotificationTap;

  const CustomUserAppBar({super.key, this.onNotificationTap});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverAsync = ref.watch(driverProvider);
    final theme = Theme.of(context);

    return AppBar(
      // Modern, flat look
      elevation: 0,
      backgroundColor: theme.colorScheme.primary,
      toolbarHeight: preferredSize.height,
      systemOverlayStyle: SystemUiOverlayStyle(
        // Set status bar icons to light for better contrast
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleSpacing: 0,
      // Use AnimatedSwitcher for a smooth transition between states
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: driverAsync.when(
          data: (driverState) => _AppBarContent(
            key: const ValueKey('data'),
            driverState: driverState,
            onNotificationTap: onNotificationTap,
          ),
          loading: () => const _AppBarLoadingState(key: ValueKey('loading')),
          error: (_, __) => const _AppBarErrorState(key: ValueKey('error')),
        ),
      ),
    );
  }
}

/// Widget to display the actual app bar content
class _AppBarContent extends ConsumerWidget {
  final dynamic driverState; // Replace with your actual DriverState model
  final void Function()? onNotificationTap;

  const _AppBarContent({
    super.key,
    required this.driverState,
    this.onNotificationTap,
  });

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (driverState?.driver == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final driver = driverState.driver!;
    final photoUrl = driver.profilePhotoUrl;
    final isNetwork = photoUrl?.startsWith('http') ?? false;
    final imageProvider = isNetwork
        ? NetworkImage(photoUrl!)
        : const AssetImage('assets/images/profile.jpg') as ImageProvider;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          /// --- Avatar ---
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.onPrimary.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundImage: imageProvider,
              backgroundColor: theme.colorScheme.primaryContainer,
            ),
          ),
          const SizedBox(width: 12),

          /// --- Welcome Text ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _greeting(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  driver.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          /// --- Action Buttons ---
          _RoundedIconButton(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifications',
            onPressed:
                onNotificationTap ??
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
          ),

          /// --- Online/Offline Switch ---
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: driverState.isOnline,
              onChanged: (value) =>
                  ref.read(driverProvider.notifier).toggleOnline(value),
              activeColor: Colors.greenAccent,
              inactiveThumbColor: Colors.grey.shade300,
              inactiveTrackColor: Colors.grey.shade600,
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
                if (states.contains(WidgetState.selected)) {
                  return Icon(Icons.check, color: theme.primaryColor);
                }
                return Icon(Icons.close, color: Colors.grey.shade800);
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// A shimmer placeholder for the loading state
class _AppBarLoadingState extends StatelessWidget {
  const _AppBarLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shimmerColor = theme.colorScheme.onPrimary.withOpacity(0.15);
    final shimmerHighlightColor = theme.colorScheme.onPrimary.withOpacity(0.3);

    return Shimmer.fromColors(
      baseColor: shimmerColor,
      highlightColor: shimmerHighlightColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const CircleAvatar(radius: 24, backgroundColor: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(height: 14, width: 100, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(height: 16, width: 140, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const CircleAvatar(radius: 20, backgroundColor: Colors.white),
            const SizedBox(width: 8),
            Container(
              height: 30,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget to display when there's an error
class _AppBarErrorState extends StatelessWidget {
  const _AppBarErrorState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onError,
          ),
          const SizedBox(width: 8),
          Text(
            'Error loading data',
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
        ],
      ),
    );
  }
}

/// A more refined icon button
class _RoundedIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _RoundedIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: theme.colorScheme.onPrimary,
        backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.1),
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}
