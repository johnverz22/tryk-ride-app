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
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 0,
      toolbarHeight: preferredSize.height,
      title: user != null
          ? CustomTopBar(
              userName: user.fullName,
              profileImageUrl: user.profilePhotoUrl ?? 'https://example.com/default.jpg',
            )
          : const SizedBox.shrink(),
    );
  }
}
