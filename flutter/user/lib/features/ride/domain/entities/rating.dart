class Rating {
  final int ratingValue;
  final String? review;

  Rating({required this.ratingValue, this.review});

  Map<String, dynamic> toJson() {
    return {'rating': ratingValue, 'review': review};
  }
}
