import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location_model.dart';

abstract class LocationRemoteDataSource {
  Future<List<LocationModel>> fetchSavedLocations(String token);
  Future<LocationModel> addSavedLocation(
    String token,
    String name,
    LatLng latLng,
  );
  Future<LocationModel> updateSavedLocation(
    String token,
    int id,
    String name,
    LatLng latLng,
  );
  Future<void> deleteSavedLocation(String token, int id);
}
