import 'package:flutter/material.dart';
import '../../../widgets/custom_top_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: const [
          CustomTopBar(
            userName: 'John Doe',
            profileImageUrl: 'https://example.com/profile.jpg',
          ),
          Expanded(
            child: Center(child: Text('Home Content')),
          ),
        ],
      ),
    );
  }
}
