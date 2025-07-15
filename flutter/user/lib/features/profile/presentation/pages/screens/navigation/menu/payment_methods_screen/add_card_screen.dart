import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../../../../widgets/widgets.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  bool isSaving = false;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(_onFieldChanged);
    _expiryController.addListener(_onExpiryChanged);
    _cvvController.addListener(_onFieldChanged);
    _nameController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {
      _isModified =
          _cardNumberController.text.isNotEmpty ||
          _expiryController.text.isNotEmpty ||
          _cvvController.text.isNotEmpty ||
          _nameController.text.isNotEmpty;
    });
  }

  void _onExpiryChanged() {
    _onFieldChanged(); // track modification

    final text = _expiryController.text.replaceAll('/', '');
    if (text.length > 2) {
      final formatted = '${text.substring(0, 2)}/${text.substring(2)}';
      if (_expiryController.text != formatted) {
        _expiryController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitCard() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => isSaving = true);

    try {
      final baseUrl = dotenv.env['BASE_URL'];
      final token = await const FlutterSecureStorage().read(key: 'token');

      if (baseUrl == null || token == null) {
        throw Exception('Missing BASE_URL or token');
      }

      final cardNumber = _cardNumberController.text.trim();
      final expiry = _expiryController.text.trim();
      final parts = expiry.split('/');
      final expiryMonth = int.tryParse(parts[0]);
      final expiryYear = int.tryParse(parts[1]) != null
          ? 2000 + int.parse(parts[1])
          : null;

      if (expiryMonth == null || expiryYear == null) {
        throw Exception('Invalid expiry format');
      }

      final cardData = {
        "provider": _detectCardProvider(cardNumber),
        "type": "card",
        "token": cardNumber, // Use real token in production
        "last_four": cardNumber.substring(cardNumber.length - 4),
        "expiry_month": expiryMonth,
        "expiry_year": expiryYear,
        "is_default": true,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/payment-methods'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(cardData),
      );

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card added successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error['message'] ?? 'Failed to add card'}'),
          ),
        );
        Navigator.pop(context, false);
      }
    } catch (e) {
      debugPrint('Error submitting card: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while adding card')),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  String _detectCardProvider(String number) {
    if (number.startsWith('4')) return 'Visa';
    if (number.startsWith(RegExp(r'5[1-5]'))) return 'Mastercard';
    if (number.startsWith('34') || number.startsWith('37')) return 'Amex';
    if (number.startsWith('6')) return 'Discover';
    return 'null';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Credit/Debit Card')),
      bottomSheet: SaveChangesButton(
        isEnabled: _isModified && !isSaving,
        onPressed: () {
          FocusScope.of(context).unfocus();
          _submitCard();
        },
        label: 'Save Card',
        icon: Icons.credit_card,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            children: [
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
                maxLength: 16,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.length != 16) {
                    return 'Enter a valid 16-digit card number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _expiryController,
                decoration: const InputDecoration(
                  labelText: 'Expiry (MM/YY)',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                maxLength: 5,
                inputFormatters: [ExpiryDateFormatter()],
                validator: (value) {
                  if (value == null ||
                      !RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                    return 'Enter expiry as MM/YY';
                  }

                  final parts = value.split('/');
                  final month = int.tryParse(parts[0]);
                  final year = int.tryParse(parts[1]);

                  if (month == null || month < 1 || month > 12) {
                    return 'Enter a valid month (01–12)';
                  }

                  final now = DateTime.now();
                  final fourDigitYear = 2000 + year!;
                  final expiryDate = DateTime(fourDigitYear, month + 1, 0);

                  if (expiryDate.isBefore(now)) {
                    return 'Card is expired';
                  }

                  return null;
                },
              ),
              TextFormField(
                controller: _cvvController,
                decoration: const InputDecoration(
                  labelText: 'CVV',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.length < 3 || value.length > 4) {
                    return 'Enter valid CVV';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Cardholder Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter cardholder name'
                    : null,
              ),
              const SizedBox(height: 80), // space for bottomSheet
            ],
          ),
        ),
      ),
    );
  }
}

class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) return newValue;

    // Only allow max 4 digits (MMYY)
    if (digits.length > 4) {
      digits = digits.substring(0, 4);
    }

    // Validate month if at least 1 digit
    if (digits.isNotEmpty) {
      final firstDigit = int.parse(digits[0]);
      if (firstDigit > 1) {
        // Invalid start of month (e.g. 3x), so block it
        return oldValue;
      }
    }

    // Validate month if at least 2 digits
    if (digits.length >= 2) {
      final month = int.parse(digits.substring(0, 2));
      if (month < 1 || month > 12) {
        // Invalid month
        return oldValue;
      }
    }

    // Format with `/`
    String formatted = digits;
    if (digits.length >= 3) {
      formatted = '${digits.substring(0, 2)}/${digits.substring(2)}';
    } else if (digits.length >= 2) {
      formatted = digits.substring(0, 2);
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
