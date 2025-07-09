import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:user/features/user/data/models/payment_method_model.dart';
import 'package:user/features/user/data/models/wallet_model.dart';

/// Combined Payment Info model (Wallet + Payment Methods)
class PaymentInfo {
  final Wallet wallet;
  final List<PaymentMethod> paymentMethods;

  PaymentInfo({required this.wallet, required this.paymentMethods});

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      wallet: Wallet.fromJson(json['wallet']),
      paymentMethods: (json['payment_methods'] as List)
          .map((e) => PaymentMethod.fromJson(e))
          .toList(),
    );
  }
}

/// Async Notifier that manages PaymentInfo (wallet + payment methods)
class PaymentInfoNotifier extends AsyncNotifier<PaymentInfo> {
  @override
  Future<PaymentInfo> build() async {
    return await _fetchPaymentInfo();
  }

  Future<PaymentInfo> _fetchPaymentInfo() async {
    final token = await const FlutterSecureStorage().read(key: 'token');
    final baseUrl = dotenv.env['BASE_URL'];

    if (baseUrl == null || token == null) {
      throw Exception('Missing base URL or token');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/payment-info'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return PaymentInfo.fromJson(data);
    } else {
      throw Exception('Failed to fetch payment info (${response.statusCode})');
    }
  }

  /// Public method to manually refresh payment info
  Future<void> refreshPaymentInfo() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPaymentInfo());
  }
}

/// Main provider for fetching & refreshing payment info
final paymentInfoProvider =
    AsyncNotifierProvider<PaymentInfoNotifier, PaymentInfo>(
      () => PaymentInfoNotifier(),
    );

/// --- Derived Providers using AsyncNotifierProvider ---

/// Wallet from combined PaymentInfo
final walletProvider = Provider<Wallet?>((ref) {
  final paymentInfo = ref.watch(paymentInfoProvider).value;
  return paymentInfo?.wallet;
});

/// Payment methods from combined PaymentInfo
final paymentMethodsProvider = Provider<List<PaymentMethod>>((ref) {
  final paymentInfo = ref.watch(paymentInfoProvider).value;
  return paymentInfo?.paymentMethods ?? [];
});

/// Wallet formatted balance (e.g. ₱0.00)
final walletFormattedBalanceProvider = Provider<String>((ref) {
  final wallet = ref.watch(walletProvider);
  return wallet?.formattedBalance ?? '₱0.00';
});

/// Filtered digital wallets (e.g., GCash, Maya)
final digitalWalletsProvider = Provider<List<PaymentMethod>>((ref) {
  final methods = ref.watch(paymentMethodsProvider);
  return methods.where((m) => m.type.toLowerCase() == 'wallet').toList();
});

/// Filtered cards
final cardsProvider = Provider<List<PaymentMethod>>((ref) {
  final methods = ref.watch(paymentMethodsProvider);
  return methods.where((m) => m.type.toLowerCase() == 'card').toList();
});

/// Flags for available digital wallet providers
final hasGcashProvider = Provider<bool>((ref) {
  final wallets = ref.watch(digitalWalletsProvider);
  return wallets.any((m) => m.provider.toLowerCase().contains('gcash'));
});

final hasMayaProvider = Provider<bool>((ref) {
  final wallets = ref.watch(digitalWalletsProvider);
  return wallets.any((m) => m.provider.toLowerCase().contains('maya'));
});
