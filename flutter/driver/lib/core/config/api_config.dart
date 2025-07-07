import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static const String prodBaseUrl = 'https://your-live-server.com/api';

  static final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost';
}