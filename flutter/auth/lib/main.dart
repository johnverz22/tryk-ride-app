import 'package:auth/app.dart';
import 'package:auth/core/providers/shared_prefs_provider.dart';
import 'package:auth/core/services/shared_prefs_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await dotenv.load();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFAFAFA),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  debugPaintSizeEnabled = false;

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(SharedPrefsService(prefs)),
      ],
      child: const MainApp(),
    ),
  );
}
