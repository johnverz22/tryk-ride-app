import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RideSocketService {
  WebSocketChannel? _channel;
  late final String _baseUrl;
  final Dio _dio;

  RideSocketService(this._dio);

  void init(int rideId, void Function(dynamic data) onUpdate) {
    if (!dotenv.isInitialized) {
      throw Exception(
        'dotenv not initialized. Call dotenv.load() before using RideSocketService.',
      );
    }

    final host = dotenv.env['REVERB_HOST'] ?? 'localhost';
    final port = dotenv.env['REVERB_PORT'] ?? '6001';
    final scheme = dotenv.env['REVERB_SCHEME'] ?? 'ws';

    _baseUrl = '$scheme://$host:$port';

    final uri = Uri.parse(
      '$_baseUrl/app/${dotenv.env['REVERB_APP_KEY']}'
      '?protocol=7&client=flutter&version=1.0&flash=false',
    );

    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen(
      (message) async {
        print('🔁 Raw message: $message');

        final data = jsonDecode(message);
        final event = data['event'];
        final payload = data['data'];

        print('🔔 Received event: $event');
        print('📦 Received payload: $payload');

        // 🔥🔥 ADD THIS TO REPLY TO SERVER
        if (event == 'pusher:ping') {
          _channel?.sink.add(jsonEncode({'event': 'pusher:pong'}));
          print('🏓 Sent pong in response to ping');
        }

        if (event == 'pusher:connection_established') {
          final socketData = jsonDecode(payload);
          final socketId = socketData['socket_id'];
          print('🔌 Socket ID: $socketId');
          await _subscribeToRideChannel(rideId, socketId);
        }

        if (event.toString().contains('RideStatusUpdated')) {
          print("✅ RideStatusUpdated event triggered");
          final parsed = _parsePayload(payload);
          print('✅ Parsed payload: $parsed');
          onUpdate(parsed);
        }
      },
      onError: (error) => print('❌ WebSocket error: $error'),
      onDone: () => print('🔌 WebSocket connection closed'),
    );
  }

  Future<void> _subscribeToRideChannel(int rideId, String socketId) async {
    final channelName = 'private-ride.$rideId';

    try {
      final token = await const FlutterSecureStorage().read(key: 'token');
      print('Headers: ${_dio.options.headers}');
      final authResponse = await _dio.post(
        '/broadcasting/auth',
        data: {'socket_id': socketId, 'channel_name': channelName},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      final auth = authResponse.data['auth'];

      final payload = jsonEncode({
        'event': 'pusher:subscribe',
        'data': {'channel': channelName, 'auth': auth},
      });

      _channel?.sink.add(payload);
      print('Subscribed to $channelName with auth');
    } catch (e) {
      print('Subscription auth failed: $e');
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  dynamic _parsePayload(dynamic payload) {
    try {
      if (payload is String) return jsonDecode(payload);
      return payload;
    } catch (_) {
      return payload;
    }
  }
}
