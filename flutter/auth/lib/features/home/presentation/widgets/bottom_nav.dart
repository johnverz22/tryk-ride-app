import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_bar_provider.dart';

class MainNavigation extends ConsumerWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the current selected page from Riverpod
    final isOnline = ref.watch(switchProvider);

    // Use the reusable NavigationContainer widget
    return BottomAppBar(
      child: Row(
        children: [
          IconButton(icon: Icon(Icons.menu), onPressed: () {}),
          Expanded(
            child: TextButton(
              style: ButtonStyle(
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                padding: WidgetStateProperty.all(EdgeInsets.zero),
              ),
              onPressed: () {
                debugPrint("Banana");
              },
              child: isOnline
                  ? Text(
                      "Online",
                      style: TextStyle(color: Colors.greenAccent[700]),
                    )
                  : Text("Offline", style: TextStyle(color: Colors.grey[800])),
            ),
          ),
          IconButton(icon: Icon(Icons.settings), onPressed: () {}),
        ],
      ),
    );
  }
}
