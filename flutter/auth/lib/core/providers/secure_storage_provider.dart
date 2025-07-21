import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/secure_storage_service.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  const storage = FlutterSecureStorage();
  return SecureStorageService(storage);
});
