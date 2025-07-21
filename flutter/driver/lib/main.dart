import 'package:driver/app.dart';
import 'package:driver/core/providers/shared_prefs_provider.dart';
import 'package:driver/core/services/shared_prefs_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final prefs = await SharedPreferences.getInstance();
  
  await dotenv.load();
  debugPaintSizeEnabled = false;
  runApp(
    ProviderScope(
      overrides: [
          sharedPrefsProvider.overrideWithValue(SharedPrefsService(prefs)),
        ],
      child: const MainApp())
  );
}