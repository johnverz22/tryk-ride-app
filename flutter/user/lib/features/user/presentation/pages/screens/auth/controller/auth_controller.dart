import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../../core/services/auth_service.dart';
import '../../../../providers/user_provider.dart';

/// Provide AuthService for better testability
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Provide AuthController with dependency injection
final authControllerProvider =
    ChangeNotifierProvider.autoDispose<AuthController>((ref) {
      final authService = ref.read(authServiceProvider);
      return AuthController(ref: ref, authService: authService);
    });

class AuthController extends ChangeNotifier {
  final Ref ref;
  final AuthService authService;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  bool get isLogin => _isLogin;
  bool get loading => _loading;
  String? get error => _error;

  AuthController({required this.ref, required this.authService});

  void toggleMode() {
    _isLogin = !_isLogin;
    _error = null;
    if (_isLogin) nameController.clear();
    notifyListeners();
  }

  Future<void> submit(BuildContext context) async {
    if (_loading) return;

    _setLoading(true);
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      final response = _isLogin
          ? await authService.login(email, password)
          : await authService.register(name, email, password);

      if (response.success && response.token != null && response.user != null) {
        await ref
            .read(userProvider.notifier)
            .setUser(response.user!, response.token!);
      } else {
        _setError('Authentication failed. Try again.');
      }
    } catch (e) {
      _setError('An error occurred. Please try again.');
    }

    _setLoading(false);
  }

  void _setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
