import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final tokenProvider = FutureProvider<String?>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  return await storage.read(key: 'token');
});
