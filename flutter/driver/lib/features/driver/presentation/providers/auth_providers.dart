import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'driver_provider.dart';

/// Provider to check if the driver is logged in
final isLoggedInProvider = Provider<bool>((ref) {
  final asyncDriverState = ref.watch(driverProvider);
  return asyncDriverState.maybeWhen(
    data: (driverState) => driverState.isAuthenticated,
    orElse: () => false,
  );
});
