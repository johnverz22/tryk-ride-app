import 'package:driver/presentation/notifiers/driver_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final driverProvider = StateNotifierProvider<DriverNotifier, DriverState>(
  (ref) => DriverNotifier(),
);