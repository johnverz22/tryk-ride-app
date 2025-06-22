import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the current index of the selected page.
final selectedPageProvider = StateProvider<int>((ref) => 0);
