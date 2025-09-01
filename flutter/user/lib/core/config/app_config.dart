import '../services/load_balancer_service.dart';

class AppConfig {
  // Load Balancer Configuration
  static const bool enableLoadBalancer = bool.fromEnvironment(
    'ENABLE_LOAD_BALANCER',
    defaultValue: false,
  );
  
  static const LoadBalancerStrategy loadBalancerStrategy = LoadBalancerStrategy.roundRobin;
  
  static const List<Map<String, dynamic>> serverEndpoints = [
    {
      'url': 'https://api1.yourapp.com',
      'weight': 3,
      'region': 'us-east',
    },
    {
      'url': 'https://api2.yourapp.com', 
      'weight': 2,
      'region': 'us-west',
    },
    {
      'url': 'https://api3.yourapp.com',
      'weight': 1,
      'region': 'eu-west',
    },
  ];

  // Message Queue Configuration
  static const bool enableMessageQueue = bool.fromEnvironment(
    'ENABLE_MESSAGE_QUEUE',
    defaultValue: false,
  );
  
  static const String messageQueueType = String.fromEnvironment(
    'MESSAGE_QUEUE_TYPE',
    defaultValue: 'redis',
  );
  
  static const String messageQueueUrl = String.fromEnvironment(
    'MESSAGE_QUEUE_URL',
    defaultValue: 'redis://localhost:6379',
  );

  // Real-time Features
  static const bool enableRealTimeTracking = bool.fromEnvironment(
    'ENABLE_REAL_TIME_TRACKING',
    defaultValue: true,
  );
  
  static const bool enablePushNotifications = bool.fromEnvironment(
    'ENABLE_PUSH_NOTIFICATIONS',
    defaultValue: true,
  );

  // Performance Settings
  static const int maxConcurrentRequests = int.fromEnvironment(
    'MAX_CONCURRENT_REQUESTS',
    defaultValue: 10,
  );
  
  static const int requestTimeoutSeconds = int.fromEnvironment(
    'REQUEST_TIMEOUT_SECONDS',
    defaultValue: 30,
  );
  
  static const int healthCheckIntervalSeconds = int.fromEnvironment(
    'HEALTH_CHECK_INTERVAL_SECONDS',
    defaultValue: 60,
  );

  // Cache Settings
  static const bool enableCaching = bool.fromEnvironment(
    'ENABLE_CACHING',
    defaultValue: true,
  );
  
  static const int cacheExpirationSeconds = int.fromEnvironment(
    'CACHE_EXPIRATION_SECONDS',
    defaultValue: 300, // 5 minutes
  );

  // Development/Production Settings
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );
  
  static const bool enableDebugLogs = bool.fromEnvironment(
    'ENABLE_DEBUG_LOGS',
    defaultValue: !isProduction,
  );

  // Feature Flags
  static const Map<String, bool> featureFlags = {
    'surge_pricing': bool.fromEnvironment('FEATURE_SURGE_PRICING', defaultValue: false),
    'driver_ratings': bool.fromEnvironment('FEATURE_DRIVER_RATINGS', defaultValue: true),
    'ride_sharing': bool.fromEnvironment('FEATURE_RIDE_SHARING', defaultValue: false),
    'scheduled_rides': bool.fromEnvironment('FEATURE_SCHEDULED_RIDES', defaultValue: false),
    'multi_stop_rides': bool.fromEnvironment('FEATURE_MULTI_STOP_RIDES', defaultValue: false),
  };

  // Get feature flag value
  static bool isFeatureEnabled(String feature) {
    return featureFlags[feature] ?? false;
  }

  // Environment-specific configurations
  static Map<String, dynamic> getEnvironmentConfig() {
    if (isProduction) {
      return {
        'api_base_url': 'https://api.yourapp.com',
        'websocket_url': 'wss://ws.yourapp.com',
        'redis_url': 'redis://prod-redis.yourapp.com:6379',
        'enable_analytics': true,
        'enable_crash_reporting': true,
      };
    } else {
      return {
        'api_base_url': 'https://dev-api.yourapp.com',
        'websocket_url': 'wss://dev-ws.yourapp.com',
        'redis_url': 'redis://dev-redis.yourapp.com:6379',
        'enable_analytics': false,
        'enable_crash_reporting': false,
      };
    }
  }
}