import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';

class CustomUserAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomUserAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(90);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final theme = Theme.of(context);

    return userAsync.when(
      data: (userState) {
        final user = userState?.user;
        if (user == null) return const SizedBox.shrink();

        final photoUrl = user.profilePhotoUrl;
        final isNetwork = photoUrl?.startsWith('http') ?? false;
        final imageProvider = isNetwork
            ? NetworkImage(photoUrl!)
            : const AssetImage('assets/images/profile.jpg') as ImageProvider;

        return AppBar(
          backgroundColor: theme.colorScheme.primary,
          surfaceTintColor: Colors.transparent,
          elevation: 0.3,
          toolbarHeight: preferredSize.height,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                /// ─── Avatar ───
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundImage: imageProvider,
                    backgroundColor: Colors.grey[300],
                  ),
                ),
                const SizedBox(width: 14),

                /// ─── Welcome Text ───
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _greeting(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimary.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                /// ─── Action Buttons ───
                const SizedBox(width: 12),
                _RoundedIconButton(
                  icon: Icons.notifications_outlined,
                  tooltip: 'Notifications',
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
                _RoundedIconButton(
                  icon: Icons.chat_outlined,
                  tooltip: 'Messages',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        );
      },
      loading: () => AppBar(
        backgroundColor: theme.colorScheme.primary,
        toolbarHeight: preferredSize.height,
        elevation: 0.3,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const CircleAvatar(radius: 26, backgroundColor: Colors.white24),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: 80, color: Colors.white24),
                  SizedBox(height: 6),
                  Container(height: 14, width: 120, color: Colors.white24),
                ],
              ),
            ],
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }
}

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
    final color = Theme.of(context).colorScheme.onPrimary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        tooltip: tooltip,
        onPressed: onPressed,
        splashRadius: 24,
      ),
    );
  }
}
