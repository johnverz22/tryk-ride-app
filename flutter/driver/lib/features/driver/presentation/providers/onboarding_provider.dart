import 'package:flutter_riverpod/flutter_riverpod.dart';

// State class to track onboarding completion
class OnboardingState {
  final bool isComplete;
  OnboardingState({this.isComplete = false});
}

// Notifier to update onboarding state
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(OnboardingState());

  Future<void> completeOnboarding() async {
    state = OnboardingState(isComplete: true);
    // You might want to persist this status in local storage/shared prefs here
  }
}

// Provider for onboarding state
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
      (ref) => OnboardingNotifier(),
    );
