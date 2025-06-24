import 'package:driver/features/skeleton/providers/app_bar_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomUserAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomUserAppBar({super.key});

  // Switch icon states based on the switch state
  static const WidgetStateProperty<Icon> thumbIcon = WidgetStateProperty<Icon>.fromMap(
    <WidgetStatesConstraint, Icon>{
      WidgetState.selected: Icon(Icons.check),
      WidgetState.any: Icon(Icons.close),
    },
  );

  @override
  Size get preferredSize => const Size.fromHeight(75);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the switchProvider to get the current state of the switch
    final isSwitched = ref.watch(switchProvider);

    return AppBar(
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
      leading: IconButton(
        icon: CircleAvatar(
            radius: 22,
            backgroundImage: AssetImage('assets/images/default_avatar.png'),
          ),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      title: Container(
        alignment: Alignment.center,
        child: Text("B A N A N A"),
        ),
      actions: [
        Switch(
          thumbIcon: thumbIcon,
          value: isSwitched,
          onChanged: (value) {
            ref.read(switchProvider.notifier).state = value;
          },
          activeColor: Colors.greenAccent,
          inactiveThumbColor: Colors.grey,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}