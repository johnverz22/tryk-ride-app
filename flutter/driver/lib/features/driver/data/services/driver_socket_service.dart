// services/driver_socket_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class DriverSocketService {
  WebSocketChannel? _channel;
  final Dio _dio;
  String? _socketId;

  StreamController<Map<String, dynamic>>? _rideRequestController;
  StreamController<int>? _rideCancellationController;

  DriverSocketService(this._dio);

  // --- Stream Getters ---
  Stream<Map<String, dynamic>> get rideRequestStream {
    _rideRequestController ??=
        StreamController<Map<String, dynamic>>.broadcast();
    return _rideRequestController!.stream;
  }

  Stream<int> get rideCancellationStream {
    _rideCancellationController ??= StreamController<int>.broadcast();
    return _rideCancellationController!.stream;
  }

  void init(int driverId) {
    if (_channel != null && _channel!.closeCode == null) {
      debugPrint('[DriverSocket] Already connected.');
      return;
    }

    final host = dotenv.env['REVERB_HOST'];
    final port = dotenv.env['REVERB_PORT'];
    final scheme = dotenv.env['REVERB_SCHEME'];
    final appKey = dotenv.env['REVERB_APP_KEY'];
    final wsUrl =
        '$scheme://$host:$port/app/$appKey?protocol=7&client=flutter&version=1.0';

    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel!.stream.listen(
      (message) {
        final data = jsonDecode(message);
        final event = data['event'];
        final payload = data['data'];

        debugPrint('[DriverSocket] Event: $event');

        if (event == 'pusher:connection_established') {
          _socketId = jsonDecode(payload)['socket_id'];
          _subscribeToDriverChannel(driverId);
        } else if (event.toString().contains('NewRideRequest')) {
          debugPrint('[DriverSocket] NewRideRequest received');
          final rideData = _parsePayload(payload);
          if (rideData['ride'] != null) {
            _rideRequestController?.add(rideData['ride']);
          }
        }
        // --- NEW: Handle the RideCancelled event ---
        else if (event.toString().contains('RideCancelled')) {
          debugPrint('[DriverSocket] RideCancelled received');
          final cancellationData = _parsePayload(payload);
          final rideId = cancellationData['ride_id'] as int?;
          if (rideId != null) {
            // Add the cancelled ride's ID to the cancellation stream
            _rideCancellationController?.add(rideId);
          }
        } else if (event == 'pusher:ping') {
          _channel?.sink.add(jsonEncode({'event': 'pusher:pong'}));
        }
      },
      onError: (error) {
        debugPrint('[DriverSocket] Error: $error');
        _rideRequestController?.addError(error);
        _rideCancellationController?.addError(error);
      },
      onDone: () {
        debugPrint('[DriverSocket] Connection closed.');
      },
    );
  }

  Future<void> _subscribeToDriverChannel(int driverId) async {
    if (_socketId == null) return;

    final privateChannelName = 'driver.$driverId';
    _channel?.sink.add(
      jsonEncode({
        'event': 'pusher:subscribe',
        'data': {'channel': privateChannelName},
      }),
    );
    debugPrint(
      '[DriverSocket] Subscribed to PRIVATE channel: $privateChannelName',
    );

    const publicChannelName = 'public-ride-offers';
    _channel?.sink.add(
      jsonEncode({
        'event': 'pusher:subscribe',
        'data': {'channel': publicChannelName},
      }),
    );
    debugPrint(
      '[DriverSocket] Subscribed to PUBLIC channel: $publicChannelName',
    );
  }

  void disconnect() {
    debugPrint('[DriverSocket] Disconnecting...');
    _channel?.sink.close();
    _channel = null;
    _rideRequestController?.close();
    _rideRequestController = null;
    _rideCancellationController?.close();
    _rideCancellationController = null;
  }

  dynamic _parsePayload(dynamic payload) {
    try {
      return (payload is String) ? jsonDecode(payload) : payload;
    } catch (_) {
      return payload;
    }
  }
}
