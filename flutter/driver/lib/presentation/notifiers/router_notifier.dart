import 'package:driver/presentation/providers/driver_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(this.ref) {
    ref.listen(driverProvider, (_, _) => notifyListeners());
  }

  final Ref ref;
}