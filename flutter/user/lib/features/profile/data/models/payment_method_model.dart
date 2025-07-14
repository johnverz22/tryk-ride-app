class PaymentMethod {
  final String id;
  final String type;
  final String provider;
  final String lastFour;
  final String expiryMonth;
  final String expiryYear;
  final String? label;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.provider,
    required this.lastFour,
    required this.expiryMonth,
    required this.expiryYear,
    this.label,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'].toString(),
      type: json['type'].toString(),
      provider: json['provider'].toString(),
      lastFour: (json['last_four'] ?? '').toString(),
      expiryMonth: json['expiry_month'].toString(),
      expiryYear: json['expiry_year'].toString(),
      label: json['label']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'provider': provider,
      'lastFour': lastFour,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      if (label != null) 'label': label,
    };
  }
}
