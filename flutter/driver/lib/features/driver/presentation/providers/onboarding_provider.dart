import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingState {
  final bool isComplete;
  OnboardingState({this.isComplete = false});
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(OnboardingState());

  static const _onboardingKey = 'onboarding_complete';

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final complete = prefs.getBool(_onboardingKey) ?? false;
    state = OnboardingState(isComplete: complete);
    _loaded = true;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    state = OnboardingState(isComplete: true);
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
      (ref) => OnboardingNotifier(),
    );

final onboardingLoadedProvider = FutureProvider<void>((ref) async {
  await ref.read(onboardingProvider.notifier).ensureLoaded();
});
