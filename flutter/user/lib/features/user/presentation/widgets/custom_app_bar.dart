import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'custom_top_bar.dart';

class CustomUserAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomUserAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(75);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

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
              userName: user.fullName,
              profileImageUrl: (user.profilePhotoUrl ?? '').isNotEmpty
                ? user.profilePhotoUrl!
                : 'assets/images/default_avatar.png',
            )
          : const SizedBox.shrink(),
    );
  }
}
