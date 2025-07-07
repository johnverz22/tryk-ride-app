// Provider for onboarding state
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/onboarding_notifier.dart';

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
      (ref) => OnboardingNotifier(),
    );