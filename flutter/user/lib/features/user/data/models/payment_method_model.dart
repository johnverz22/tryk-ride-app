class PaymentMethod {
  final String id;
  final String type;
  final String provider;
  final String lastFour;
  final String? label;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.provider,
    required this.lastFour,
    this.label,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'].toString(),
      type: json['type'].toString(),
      provider: json['provider'].toString(),
      lastFour: (json['last_four'] ?? '').toString(),
      label: json['label']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'provider': provider,
      'lastFour': lastFour,
      if (label != null) 'label': label,
    };
  }
}
