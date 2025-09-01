import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import '../../business/entities/user_entity.dart';
import '../../business/usecases/get_user_usecase.dart';
import '../../business/usecases/update_user_usecase.dart';
import '../../business/usecases/login_usecase.dart';
import '../../business/usecases/logout_usecase.dart';
import '../../../../core/errors/failures.dart';

class UserViewModel extends ChangeNotifier {
  final GetUserUseCase _getUserUseCase;
  final UpdateUserUseCase _updateUserUseCase;
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;

  UserViewModel({
    required GetUserUseCase getUserUseCase,
    required UpdateUserUseCase updateUserUseCase,
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
  })  : _getUserUseCase = getUserUseCase,
        _updateUserUseCase = updateUserUseCase,
        _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase;

  UserEntity? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserEntity? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null && _token != null;

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _setUser(UserEntity? user) {
    _user = user;
    notifyListeners();
  }

  void _setToken(String? token) {
    _token = token;
    notifyListeners();
  }

  // Public methods
  Future<void> loadUser() async {
    _setLoading(true);
    _setError(null);

    final result = await _getUserUseCase.call();
    
    result.fold(
      (failure) => _setError(_mapFailureToMessage(failure)),
      (userData) {
        _setUser(userData.user);
        _setToken(userData.token);
      },
    );

    _setLoading(false);
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);

    final result = await _loginUseCase.call(
      LoginParams(email: email, password: password),
    );

    bool success = false;
    result.fold(
      (failure) => _setError(_mapFailureToMessage(failure)),
      (userData) {
        _setUser(userData.user);
        _setToken(userData.token);
        success = true;
      },
    );

    _setLoading(false);
    return success;
  }

  Future<bool> updateUser(UserEntity updatedUser) async {
    _setLoading(true);
    _setError(null);

    final result = await _updateUserUseCase.call(updatedUser);

    bool success = false;
    result.fold(
      (failure) => _setError(_mapFailureToMessage(failure)),
      (user) {
        _setUser(user);
        success = true;
      },
    );

    _setLoading(false);
    return success;
  }

  Future<void> logout() async {
    _setLoading(true);
    
    await _logoutUseCase.call();
    
    _setUser(null);
    _setToken(null);
    _setError(null);
    _setLoading(false);
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error occurred';
      case NetworkFailure:
        return 'Network connection failed';
      case AuthFailure:
        return 'Authentication failed';
      default:
        return 'An unexpected error occurred';
    }
  }
}