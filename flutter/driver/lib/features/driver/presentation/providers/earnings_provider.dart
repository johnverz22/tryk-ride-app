import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../../features/driver/data/models/earnings_model.dart';
import '../providers/driver_provider.dart';

final earningsSummaryProvider = FutureProvider.family<EarningsSummary, String>((
  ref,
  range,
) async {
  final driverState = ref.watch(driverProvider).value;

  if (driverState == null || driverState.token == null) {
    throw Exception('Driver not authenticated');
  }

  final token = driverState.token!;
  final baseUrl = dotenv.env['BASE_URL'];
  final url = Uri.parse('$baseUrl/api/driver/earnings?range=$range');

  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return EarningsSummary.fromJson(data);
  } else {
    throw Exception('Failed to fetch earnings: ${response.body}');
  }
});
