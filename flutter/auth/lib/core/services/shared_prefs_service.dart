import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  final SharedPreferences prefs;

  SharedPrefsService(this.prefs);

  Future<void> completeOnboarding() async {
    await prefs.setBool('onboarding', true);
  }

  bool getOnboarding() {
    return prefs.getBool('onboarding') ?? false;
  }

  Future<void> setUser(Map<String, dynamic> user) async {
    await prefs.setString('user', jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    String? userJson = prefs.getString('user');
    if (userJson != null) {
      return jsonDecode(userJson); // Decode the JSON string back into a Map
    }
    return null; // Return null if the user data doesn't exist
  }

  Future<void> clearAll() async {
    await prefs.clear();
  }
}
