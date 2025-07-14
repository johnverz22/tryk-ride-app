import 'package:user/config/currency.dart';

class Wallet {
  final String id;
  final double balance;

  Wallet({required this.id, required this.balance});

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'].toString(),
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'balance': balance};
  }

  String get formattedBalance {
    return currencyFormatter.format(balance);
  }
}
