import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/shared_preferences_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferencesService>((ref) {
  throw UnimplementedError(
    'Must be overridden in main using ProviderScope overrides.',
  );
});

/// Use this when you need a reactive onboarding state
final onboardingProvider = FutureProvider<bool>((ref) async {
  final preferences = ref.watch(sharedPreferencesProvider);
  return preferences.getOnboarding();
});
