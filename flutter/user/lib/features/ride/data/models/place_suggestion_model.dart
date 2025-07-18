import '../../domain/entities/place_entity.dart';

class PlaceSuggestionModel extends PlaceSuggestionEntity {
  const PlaceSuggestionModel({
    required super.placeId,
    required super.description,
  });

  factory PlaceSuggestionModel.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestionModel(
      placeId: json['place_id'] as String,
      description: json['description'] as String,
    );
  }
}
