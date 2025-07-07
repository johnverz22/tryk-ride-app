import 'package:driver/presentation/providers/skeleton_app_bar_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomUserAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomUserAppBar({super.key});

  // Switch icon states based on the switch state
  static const WidgetStateProperty<Icon> thumbIcon =
      WidgetStateProperty<Icon>.fromMap(<WidgetStatesConstraint, Icon>{
        WidgetState.selected: Icon(Icons.check),
        WidgetState.any: Icon(Icons.close),
      });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the switchProvider to get the current state of the switch
    final isSwitched = ref.watch(switchProvider);
    final isOverlayVisible = ref.watch(overlayEarnings);

    void showOverlay(BuildContext context) {
      if (!isOverlayVisible) {
        ref.read(overlayEarnings.notifier).state = true;
      } else {
        ref.read(overlayEarnings.notifier).state = false;
      }
    }

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      toolbarHeight: preferredSize.height,
      leadingWidth: 90,
      leading: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: IconButton(
          icon: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundImage: AssetImage('assets/images/profile_picture.jpg'),
            ),
          ),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      title: Container(
        height: 56,
        alignment: Alignment.center,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black, // Background color
            foregroundColor: Colors.white, // Text (and icon) color
            side: BorderSide(color: Colors.white, width: 2),
            minimumSize: Size(100, 48),
            padding: EdgeInsets.symmetric(horizontal: 16),
          ),
          onPressed: () {
            showOverlay(context);
          },
          child: Text(
            "\$345.00",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20), // Adjust as needed
          child: Transform.scale(
            scale: 1.3, // Scale up the switch (default is 1.0)
            child: Switch(
              thumbIcon: thumbIcon,
              value: isSwitched,
              onChanged: (value) {
                ref.read(switchProvider.notifier).state = value;
              },
              activeColor: Colors.greenAccent[700],
              inactiveTrackColor: Colors.grey.shade800,
              inactiveThumbColor: Colors.black,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }
}
