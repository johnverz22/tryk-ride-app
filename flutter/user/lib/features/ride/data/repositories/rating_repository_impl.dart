import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:user/features/core/errors/exceptions.dart';
import 'package:user/features/core/errors/failures.dart';
import 'package:user/features/ride/domain/entities/rating.dart';
import 'package:user/features/ride/domain/repositories/rating_repository.dart';
import 'package:user/core/services/auth_service.dart';

class RatingRepositoryImpl implements RatingRepository {
  final http.Client client;
  final AuthService authService; // Inject AuthService

  RatingRepositoryImpl({required this.client, required this.authService});

  @override
  Future<Either<Failure, void>> submitRideRating(
    int rideId,
    Rating rating,
  ) async {
    try {
      final baseUrl = dotenv.env['BASE_URL'];
      if (baseUrl == null) {
        throw ServerException('BASE_URL not found in environment variables.');
      }

      final token = await authService.getToken();
      if (token == null) {
        // This should ideally throw UnauthorizedException if token is null
        // And caught by the on UnauthorizedException block below.
        // For now, if getToken() returns null, we'll convert it to an UnauthorizedException.
        throw UnauthorizedException('Authentication token not found.');
      }

      final response = await client.post(
        Uri.parse('$baseUrl/api/rides/$rideId/rate-driver'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(rating.toJson()),
      );

      if (response.statusCode == 200) {
        return const Right(null); // Success
      } else if (response.statusCode == 401) {
        // Correct way to return UnauthorizedFailure
        return Left(UnauthorizedFailure('Unauthorized: ${response.body}'));
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        return Left(
          ServerFailure(
            message:
                json.decode(response.body)['message'] ??
                'Bad request or resource not found.',
          ),
        );
      } else {
        return Left(
          ServerFailure(
            message:
                'Failed to submit rating: ${response.statusCode} - ${response.body}',
          ),
        );
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on UnauthorizedException catch (e) {
      // Correct way to return UnauthorizedFailure
      return Left(UnauthorizedFailure(e.message));
    } on NetworkException {
      // Ensure NetworkException is defined in your exceptions.dart
      return Left(NoInternetFailure());
    } catch (e) {
      return Left(
        UnexpectedFailure('An unexpected error occurred: ${e.toString()}'),
      );
    }
  }
}
