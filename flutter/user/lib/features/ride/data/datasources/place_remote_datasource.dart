import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/place_details_model.dart';
import '../models/place_suggestion_model.dart';
import '../models/geocoded_address_model.dart';

abstract class PlaceRemoteDataSource {
  Future<List<PlaceSuggestionModel>> searchPlaces(String query);
  Future<PlaceDetailsModel> getPlaceDetails(String placeId);
  Future<GeocodedAddressModel> getPlaceNameFromLatLng(LatLng latLng);
}
