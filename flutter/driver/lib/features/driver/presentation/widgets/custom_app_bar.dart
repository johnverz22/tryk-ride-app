import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/driver_provider.dart';
import 'custom_top_bar.dart';

class CustomUserAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomUserAppBar({super.key, this.title});

  final String? title;

  @override
  Size get preferredSize => const Size.fromHeight(75);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<DriverProvider>(context).driver;

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
              profileImageUrl: user.profilePhotoUrl?.isNotEmpty == true
                  ? user.profilePhotoUrl!
                  : '',
            )
          : Text(
              title ?? '',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
    );
  }
}
