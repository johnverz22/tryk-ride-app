import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  final SharedPreferences preferences;

  SharedPreferencesService(this.preferences);

  /// Marks onboarding as complete
  Future<void> setOnboarding() async {
    await preferences.setBool('onboarding', true);
  }

  /// Returns true if onboarding was completed
  bool getOnboarding() {
    return preferences.getBool('onboarding') ?? false;
  }

  /// Clears all stored preferences (useful for logout or reset)
  Future<void> clearAll() async {
    await preferences.clear();
  }

  // You can add more shared preference accessors here if needed
}
