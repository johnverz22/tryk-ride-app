import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Load balancer strategies
enum LoadBalancerStrategy {
  roundRobin,
  leastConnections,
  random,
  weighted,
  geographicProximity,
}

class ServerEndpoint {
  final String url;
  final int weight;
  final String region;
  int currentConnections;
  bool isHealthy;
  DateTime lastHealthCheck;

  ServerEndpoint({
    required this.url,
    this.weight = 1,
    this.region = 'default',
    this.currentConnections = 0,
    this.isHealthy = true,
    DateTime? lastHealthCheck,
  }) : lastHealthCheck = lastHealthCheck ?? DateTime.now();

  ServerEndpoint copyWith({
    String? url,
    int? weight,
    String? region,
    int? currentConnections,
    bool? isHealthy,
    DateTime? lastHealthCheck,
  }) {
    return ServerEndpoint(
      url: url ?? this.url,
      weight: weight ?? this.weight,
      region: region ?? this.region,
      currentConnections: currentConnections ?? this.currentConnections,
      isHealthy: isHealthy ?? this.isHealthy,
      lastHealthCheck: lastHealthCheck ?? this.lastHealthCheck,
    );
  }
}

class LoadBalancerService {
  final List<ServerEndpoint> _servers = [];
  final LoadBalancerStrategy _strategy;
  final http.Client _httpClient;
  int _currentIndex = 0;
  final Random _random = Random();

  LoadBalancerService({
    required LoadBalancerStrategy strategy,
    http.Client? httpClient,
  })  : _strategy = strategy,
        _httpClient = httpClient ?? http.Client();

  // Add server endpoints
  void addServer(ServerEndpoint server) {
    _servers.add(server);
    debugPrint('[LoadBalancer] Added server: ${server.url}');
  }

  void addServers(List<ServerEndpoint> servers) {
    _servers.addAll(servers);
    debugPrint('[LoadBalancer] Added ${servers.length} servers');
  }

  // Remove server
  void removeServer(String url) {
    _servers.removeWhere((server) => server.url == url);
    debugPrint('[LoadBalancer] Removed server: $url');
  }

  // Get next server based on strategy
  ServerEndpoint? getNextServer({String? userRegion}) {
    final healthyServers = _servers.where((s) => s.isHealthy).toList();
    
    if (healthyServers.isEmpty) {
      debugPrint('[LoadBalancer] No healthy servers available');
      return null;
    }

    switch (_strategy) {
      case LoadBalancerStrategy.roundRobin:
        return _roundRobin(healthyServers);
      
      case LoadBalancerStrategy.leastConnections:
        return _leastConnections(healthyServers);
      
      case LoadBalancerStrategy.random:
        return _randomSelection(healthyServers);
      
      case LoadBalancerStrategy.weighted:
        return _weightedSelection(healthyServers);
      
      case LoadBalancerStrategy.geographicProximity:
        return _geographicProximity(healthyServers, userRegion);
    }
  }

  ServerEndpoint _roundRobin(List<ServerEndpoint> servers) {
    final server = servers[_currentIndex % servers.length];
    _currentIndex = (_currentIndex + 1) % servers.length;
    return server;
  }

  ServerEndpoint _leastConnections(List<ServerEndpoint> servers) {
    return servers.reduce((a, b) => 
      a.currentConnections <= b.currentConnections ? a : b
    );
  }

  ServerEndpoint _randomSelection(List<ServerEndpoint> servers) {
    return servers[_random.nextInt(servers.length)];
  }

  ServerEndpoint _weightedSelection(List<ServerEndpoint> servers) {
    final totalWeight = servers.fold<int>(0, (sum, server) => sum + server.weight);
    final randomWeight = _random.nextInt(totalWeight);
    
    int currentWeight = 0;
    for (final server in servers) {
      currentWeight += server.weight;
      if (randomWeight < currentWeight) {
        return server;
      }
    }
    
    return servers.last;
  }

  ServerEndpoint _geographicProximity(List<ServerEndpoint> servers, String? userRegion) {
    if (userRegion == null) return _roundRobin(servers);
    
    // Prefer servers in the same region
    final sameRegionServers = servers.where((s) => s.region == userRegion).toList();
    if (sameRegionServers.isNotEmpty) {
      return _leastConnections(sameRegionServers);
    }
    
    return _leastConnections(servers);
  }

  // Health check for servers
  Future<void> performHealthChecks() async {
    final futures = _servers.map((server) => _checkServerHealth(server));
    await Future.wait(futures);
  }

  Future<void> _checkServerHealth(ServerEndpoint server) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('${server.url}/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      final wasHealthy = server.isHealthy;
      server.isHealthy = response.statusCode == 200;
      server.lastHealthCheck = DateTime.now();

      if (!wasHealthy && server.isHealthy) {
        debugPrint('[LoadBalancer] Server ${server.url} is back online');
      } else if (wasHealthy && !server.isHealthy) {
        debugPrint('[LoadBalancer] Server ${server.url} is down');
      }
    } catch (e) {
      server.isHealthy = false;
      server.lastHealthCheck = DateTime.now();
      debugPrint('[LoadBalancer] Health check failed for ${server.url}: $e');
    }
  }

  // Track connection usage
  void incrementConnections(String serverUrl) {
    final server = _servers.firstWhere((s) => s.url == serverUrl);
    server.currentConnections++;
  }

  void decrementConnections(String serverUrl) {
    final server = _servers.firstWhere((s) => s.url == serverUrl);
    if (server.currentConnections > 0) {
      server.currentConnections--;
    }
  }

  // Get server statistics
  Map<String, dynamic> getStats() {
    return {
      'total_servers': _servers.length,
      'healthy_servers': _servers.where((s) => s.isHealthy).length,
      'total_connections': _servers.fold<int>(0, (sum, s) => sum + s.currentConnections),
      'servers': _servers.map((s) => {
        'url': s.url,
        'healthy': s.isHealthy,
        'connections': s.currentConnections,
        'weight': s.weight,
        'region': s.region,
        'last_health_check': s.lastHealthCheck.toIso8601String(),
      }).toList(),
    };
  }

  void dispose() {
    _httpClient.close();
  }
}