import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/load_balancer_service.dart';
import '../../../../core/services/message_queue_service.dart';

class LoginResult {
  final UserModel user;
  final String token;

  LoginResult({required this.user, required this.token});
}

abstract class UserRemoteDataSource {
  Future<LoginResult> login(String email, String password);
  Future<UserModel> updateUser(UserModel user);
  Future<String> refreshToken();
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final http.Client client;
  final LoadBalancerService? loadBalancer;
  final MessageQueueService? messageQueue;

  UserRemoteDataSourceImpl({
    required this.client,
    this.loadBalancer,
    this.messageQueue,
  });

  // Get the best server URL based on load balancing
  String _getServerUrl() {
    if (loadBalancer != null) {
      final server = loadBalancer!.getNextServer();
      if (server != null) {
        loadBalancer!.incrementConnections(server.url);
        return server.url;
      }
    }
    return ApiConfig.baseUrl;
  }

  void _releaseConnection(String serverUrl) {
    loadBalancer?.decrementConnections(serverUrl);
  }

  @override
  Future<LoginResult> login(String email, String password) async {
    final serverUrl = _getServerUrl();
    
    try {
      final response = await client.post(
        Uri.parse('$serverUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserModel.fromJson(json: data['user']);
        final token = data['token'] as String;
        
        // Publish login event to message queue
        messageQueue?.publish('user.login', {
          'user_id': user.id,
          'timestamp': DateTime.now().toIso8601String(),
          'server': serverUrl,
        });
        
        return LoginResult(user: user, token: token);
      } else if (response.statusCode == 401) {
        throw AuthException();
      } else {
        throw ServerException();
      }
    } catch (e) {
      if (e is AuthException || e is ServerException) rethrow;
      throw NetworkException();
    } finally {
      _releaseConnection(serverUrl);
    }
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    try {
      final response = await client.put(
        Uri.parse('${ApiConfig.baseUrl}/user/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(json: data['user']);
      } else if (response.statusCode == 401) {
        throw AuthException();
      } else {
        throw ServerException();
      }
    } catch (e) {
      if (e is AuthException || e is ServerException) rethrow;
      throw NetworkException();
    }
  }

  @override
  Future<String> refreshToken() async {
    try {
      final response = await client.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/refresh'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token'] as String;
      } else if (response.statusCode == 401) {
        throw AuthException();
      } else {
        throw ServerException();
      }
    } catch (e) {
      if (e is AuthException || e is ServerException) rethrow;
      throw NetworkException();
    }
  }
}