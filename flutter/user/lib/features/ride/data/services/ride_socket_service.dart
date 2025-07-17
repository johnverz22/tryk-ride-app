import 'dart:async'; // Import for StreamController
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RideSocketService {
  WebSocketChannel? _channel;
  late String _baseUrl; // 'late' is fine here as it's initialized in init()
  final Dio _dio;
  // Make sure this is initialized before any access.
  // It's declared as nullable, but we'll ensure it's non-null before use.
  StreamController<Map<String, dynamic>>? _internalStreamController;

  RideSocketService(this._dio);

  Stream<Map<String, dynamic>> init(
    int rideId,
    void Function(dynamic data) onUpdate,
  ) {
    // --- FIX START ---
    // Ensure _internalStreamController is initialized or re-initialized if closed.
    // This must happen BEFORE any return statements that rely on its stream.
    if (_internalStreamController == null ||
        _internalStreamController!.isClosed) {
      _internalStreamController =
          StreamController<Map<String, dynamic>>.broadcast();
    }
    // --- FIX END ---

    // Now, it's safe to check if a channel already exists and is open, and return its stream.
    // The _internalStreamController is guaranteed to be non-null here.
    if (_channel != null && _channel!.closeCode == null) {
      print(
        '✅ RideSocketService already initialized for ride ID: $rideId. Returning existing stream.',
      );
      return _internalStreamController!.stream;
    }

    if (!dotenv.isInitialized) {
      throw Exception(
        'dotenv not initialized. Call dotenv.load() before using RideSocketService.',
      );
    }

    final host = dotenv.env['REVERB_HOST'] ?? 'localhost';
    final port = dotenv.env['REVERB_PORT'] ?? '6001';
    final scheme = dotenv.env['REVERB_SCHEME'] ?? 'ws';

    _baseUrl = '$scheme://$host:$port';

    _channel = WebSocketChannel.connect(
      Uri.parse(
        '$_baseUrl/app/${dotenv.env['REVERB_APP_KEY']}'
        '?protocol=7&client=flutter&version=1.0&flash=false',
      ),
    );

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
          onUpdate(parsed); // Still call the callback for immediate processing
          _internalStreamController?.add(parsed); // Add to the internal stream
        }
      },
      onError: (error) {
        print('❌ WebSocket error: $error');
        _internalStreamController?.addError(
          error,
        ); // Add error to the internal stream
      },
      onDone: () {
        print('🔌 WebSocket connection closed');
        _internalStreamController?.close(); // Close the internal stream
      },
    );

    return _internalStreamController!.stream; // Return the stream
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
    print('Attempting to disconnect RideSocketService...');
    _channel?.sink.close();
    _channel = null;
    _internalStreamController?.close(); // Ensure internal stream is also closed
    _internalStreamController = null;
    print('RideSocketService disconnected.');
  }

  dynamic _parsePayload(dynamic payload) {
    try {
      if (payload is String) return jsonDecode(payload);
      return payload;
    } catch (_) {
      return payload; // Return original payload if it's not a valid JSON string
    }
  }
}
