import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';
import 'custom_top_bar.dart';

class CustomUserAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomUserAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(75);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (userState) {
        final user = userState.user;
        return AppBar(
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pinkAccent, Colors.deepPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 0,
          toolbarHeight: preferredSize.height,
          title: user != null
              ? CustomTopBar(
                  userName: user.name,
                  profileImageUrl: 'assets/images/profile.jpg',
                  // Optionally use: user.profilePhotoUrl ?? 'assets/images/profile.jpg',
                )
              : const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
