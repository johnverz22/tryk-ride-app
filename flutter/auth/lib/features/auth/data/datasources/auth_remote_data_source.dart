import 'dart:convert';
import 'dart:io';
import 'package:auth/core/errors/exceptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

final baseUrl = dotenv.env['BASE_URL'];

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String password, String name);
  Future<void> logout(String token);
  Future<UserModel> getCurrentUser(String token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException();
    } on HttpException catch (e) {
      debugPrint('remote/ds/login HttpException: ${e.message}');
      throw const NetworkException();
    } on FormatException catch (e) {
      debugPrint('remote/ds/login FormatException: ${e.message}');
      throw const UnknownException('Invalid response format');
    } on InvalidCredentialsException catch (e) {
      debugPrint('remote/ds/login InvalidCredentialsException: ${e.message}');
      throw const InvalidCredentialsException(); // Handle this custom exception
    } on ValidationException catch (e) {
      debugPrint('remote/ds/login ValidationException: ${e.message}');
      throw const ValidationException(); // Handle validation error
    } on ServerException catch (e) {
      debugPrint('remote/ds/login ServerException: ${e.message}');
      throw const ServerException(); // Handle server error
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  UserModel _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        return UserModel.fromJson(data);
      } catch (e) {
        throw const UnknownException('Failed to parse response');
      }
    } else {
      _handleErrorResponse(response);
    }
  }

  Never _handleErrorResponse(http.Response response) {
    try {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['message'] ?? 'An error occurred';

      switch (response.statusCode) {
        case 401:
          throw const InvalidCredentialsException();
        case 422:
          throw const ValidationException();
        case 500:
          throw const ServerException();
        default:
          throw UnknownException(errorMessage);
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw UnknownException('Failed to parse error response');
    }
  }

  @override
  Future<UserModel> register(String email, String password, String name) async {
    final response = await client.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'role_id': 3,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return UserModel.fromJson(data);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Registration failed');
    }
  }

  @override
  Future<void> logout(String token) async {
    final response = await client.post(
      Uri.parse('$baseUrl/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Logout failed');
    }
  }

  @override
  Future<UserModel> getCurrentUser(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UserModel.fromJson({...data, 'token': token});
    } else {
      throw Exception('Failed to get current user');
    }
  }
}
