import 'package:laravel_echo/laravel_echo.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late Echo echo;
  bool _isInitialized = false;

  void init(String token) {
    if (_isInitialized) return; // Prevent duplicate connections

    IO.Socket socket = IO.io(
      'http://your-laravel-echo-server:6001', // 🔁 Replace with your server URL
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'extraHeaders': {'Authorization': 'Bearer $token'},
      },
    );

    echo = Echo(broadcaster: EchoBroadcasterType.SocketIO, client: socket);

    echo.channel('drivers').listen('ride.request', (event) {
      print('📦 Ride requested: $event');
      // You can forward this to a provider or show a dialog here
    });

    _isInitialized = true;
  }

  void disconnect() {
    echo.disconnect();
    _isInitialized = false;
  }
}
