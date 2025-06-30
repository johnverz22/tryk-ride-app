class ApiConfig {
  // REST API base URLs
  static const String devBaseUrl = 'http://192.168.108.103:8000/api';
  static const String prodBaseUrl = 'https://your-live-server.com/api';

  // WebSocket base URLs
  static const String devWebSocketBase = 'ws://192.168.108.71:9090';
  static const String prodWebSocketBase = 'wss://your-live-server.com';

  // Pusher/Reverb App Key
  static const String reverbAppKey = 'amlovqfjlvrgvhqz7hei';

  static const bool isProduction = false;

  static String get baseUrl => isProduction ? prodBaseUrl : devBaseUrl;
  static String get webSocketBase =>
      isProduction ? prodWebSocketBase : devWebSocketBase;
}
