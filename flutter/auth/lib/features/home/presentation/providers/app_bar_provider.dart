import 'package:flutter_riverpod/flutter_riverpod.dart';

final switchProvider = StateProvider<bool>((ref) => false);

final overlayEarnings = StateProvider<bool>((ref) => false);