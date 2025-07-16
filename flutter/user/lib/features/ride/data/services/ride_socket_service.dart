import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

        if (event == 'pusher:ping') {
          _channel?.sink.add(jsonEncode({'event': 'pusher:pong'}));
          print('🏓 Sent pong in response to ping');
        }

        if (event == 'pusher:connection_established') {
          final socketData = jsonDecode(payload);
          final socketId = socketData['socket_id'];
          print('🔌 Socket ID: $socketId');
          _subscribeToRideChannel(rideId);
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

  void _subscribeToRideChannel(int rideId) {
    final channelName = 'ride.$rideId';

    final payload = jsonEncode({
      'event': 'pusher:subscribe',
      'data': {'channel': channelName},
    });

    _channel?.sink.add(payload);
    print('✅ Subscribed to public channel $channelName (no auth needed)');
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
