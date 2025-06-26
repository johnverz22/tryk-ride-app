import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';

class PaymentMethodsList extends StatelessWidget {
  const PaymentMethodsList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          PaymentCard(type: 'Visa', info: '•••• 4582'),
          PaymentCard(type: 'Mastercard', info: '•••• 7865'),
          PaymentCard(type: 'PayPal', info: 'alex@example.com'),
          AddPaymentCard(),
        ],
      ),
    );
  }
}

class PaymentCard extends StatelessWidget {
  final String type;
  final String info;

  const PaymentCard({super.key, required this.type, required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 14),
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(type, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(info, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}

class AddPaymentCard extends StatelessWidget {
  const AddPaymentCard({super.key});

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      borderType: BorderType.RRect,
      radius: const Radius.circular(16),
      dashPattern: const [6, 4],
      color: Colors.grey.shade400,
      strokeWidth: 1.2,
      child: InkWell(
        onTap: () {},
        child: Container(
          width: 180,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: Icon(Icons.add, size: 32, color: Colors.grey)),
        ),
      ),
    );
  }
}
