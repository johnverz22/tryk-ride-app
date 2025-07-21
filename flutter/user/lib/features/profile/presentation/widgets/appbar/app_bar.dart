import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/user_provider.dart';
import '../../pages/screens/appbar/wallet_screen.dart';
import '../../pages/screens/appbar/notifications_screen.dart';

class CustomUserAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomUserAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
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
        child: userAsync.when(
          data: (userState) => _AppBarContent(
            key: const ValueKey('data'),
            user: userState?.user,
          ),
          loading: () => const _AppBarLoadingState(key: ValueKey('loading')),
          error: (_, __) => const SizedBox.shrink(key: ValueKey('error')),
        ),
      ),
    );
  }
}

/// Widget to display the actual app bar content
class _AppBarContent extends StatelessWidget {
  final dynamic user; // Replace 'dynamic' with your actual User model class

  const _AppBarContent({super.key, required this.user});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      // Handle the case where user data is successfully loaded but is null
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final photoUrl = user.profilePhotoUrl;
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
                  user.name,
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
            icon: Icons.account_balance_wallet_outlined,
            tooltip: 'Wallet',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WalletScreen()),
              );
            },
          ),
          _RoundedIconButton(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
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
            const CircleAvatar(radius: 25),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 14, width: 100, color: Colors.white),
                const SizedBox(height: 6),
                Container(height: 16, width: 140, color: Colors.white),
              ],
            ),
          ],
        ),
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
        // Use onPrimary color for the icon
        foregroundColor: theme.colorScheme.onPrimary,
        // Subtle background color
        backgroundColor: theme.colorScheme.onPrimary.withValues(alpha: .1),
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}
