import 'package:flutter/foundation.dart';

class TripsProvider extends ChangeNotifier {
  // Mock data for trips
  final List<Map<String, dynamic>> _trips = [
    {
      'id': '1',
      'datetime': DateTime.now().subtract(const Duration(days: 1)),
      'pickup': 'Airport Terminal 1',
      'dropoff': 'Downtown Hotel',
      'price': 23.5,
      'payment': 'Credit Card',
      'rider': 'Anna Carter',
      'rating': 4.5,
      'status': 'Completed',
    },
    {
      'id': '2',
      'datetime': DateTime.now().add(const Duration(hours: 5)),
      'pickup': 'City Center',
      'dropoff': 'Museum District',
      'price': 12.0,
      'payment': 'Wallet',
      'rider': 'Ben Morris',
      'rating': null,
      'status': 'Upcoming',
    },
    {
      'id': '3',
      'datetime': DateTime.now().subtract(const Duration(days: 3)),
      'pickup': 'Stadium',
      'dropoff': 'Suburb 5',
      'price': 15.0,
      'payment': 'Cash',
      'rider': 'Sarah Lee',
      'rating': 4.1,
      'status': 'Canceled',
    },
  ];

  // Getter for trips
  List<Map<String, dynamic>> get trips => _trips;

  // Method to get trips by status
  List<Map<String, dynamic>> getTripsByStatus(String status) {
    return _trips.where((trip) => trip['status'] == status).toList();
  }

  // Method to search trips
  List<Map<String, dynamic>> searchTrips(String query) {
    if (query.isEmpty) {
      return _trips;
    }

    final lowercaseQuery = query.toLowerCase();
    return _trips.where((trip) {
      final pickup = trip['pickup'].toString().toLowerCase();
      final dropoff = trip['dropoff'].toString().toLowerCase();
      final rider = trip['rider'].toString().toLowerCase();

      return pickup.contains(lowercaseQuery) ||
          dropoff.contains(lowercaseQuery) ||
          rider.contains(lowercaseQuery);
    }).toList();
  }

  // Method to add a new trip
  void addTrip(Map<String, dynamic> trip) {
    _trips.add(trip);
    notifyListeners();
  }

  // Method to update a trip
  void updateTrip(String id, Map<String, dynamic> updatedTrip) {
    final index = _trips.indexWhere((trip) => trip['id'] == id);
    if (index != -1) {
      _trips[index] = updatedTrip;
      notifyListeners();
    }
  }

  // Method to delete a trip
  void deleteTrip(String id) {
    _trips.removeWhere((trip) => trip['id'] == id);
    notifyListeners();
  }
}