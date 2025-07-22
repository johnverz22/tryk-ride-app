import 'package:flutter/material.dart';

class AppError extends StatelessWidget {
  final Object error;
  const AppError({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Error: \\n$error', style: const TextStyle(color: Colors.red)),
      ),
    );
  }
} 