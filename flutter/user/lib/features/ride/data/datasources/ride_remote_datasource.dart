import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/entities/ride_details.dart';
import '../models/ride_model.dart';

abstract class RideRemoteDatasource {
  Future<int> requestRide(RideModel model);
  Future<void> cancelRide(int rideId);
  Future<RideDetails> fetchRideDetails(int rideId);
  Future<void> submitRideRating(int rideId, int rating, String? review);
  Stream<Map<String, dynamic>> streamRawDriverLocation(int rideId);
  Future<PolylineResult> getPolylineRoute(LatLng from, LatLng to);
}
