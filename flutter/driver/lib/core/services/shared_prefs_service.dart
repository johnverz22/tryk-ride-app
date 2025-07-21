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

  Future<void> clearAll() async {
    await prefs.clear();
  }
}
