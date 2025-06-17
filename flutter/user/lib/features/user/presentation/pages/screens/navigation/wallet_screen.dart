// wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../widgets/custom_top_bar.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF4F46E5); // Brand color
    final today = DateFormat('MMMM d, yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        toolbarHeight: 75,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            CustomTopBar(
              userName: 'John Doe',
              profileImageUrl: 'https://example.com/profile.jpg',
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Balance Section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Available Balance', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('\$150.00', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add Money'),
                        onPressed: () {},
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.money_off),
                        label: const Text('Withdraw'),
                        onPressed: () {},
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Payment Methods
          const Text('Payment Methods', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                paymentCard('Visa', '•••• 4582'),
                paymentCard('Mastercard', '•••• 7865'),
                paymentCard('PayPal', 'alex@example.com'),
                addPaymentCard(),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Transaction History Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {},
                child: const Text('Filter'),
              ),
            ],
          ),

          // Transaction List (simplified static entries)
          ...List.generate(3, (index) => transactionItem()),

          const SizedBox(height: 24),

          // Promotions & Credits
          const Text('Promotions & Credits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          promotionCard('Get \$5 off your next ride', 'Valid until June 30, 2025'),
          promotionCard('Invite a friend & earn rewards', 'Ongoing'),

          const SizedBox(height: 24),

          // Spending Analytics (placeholder)
          const Text('Spending Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: 150,
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const Text('Analytics Chart Placeholder'),
          ),

          const SizedBox(height: 80),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {},
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Trips'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget paymentCard(String type, String info) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.blue.shade50,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(info),
        ],
      ),
    );
  }

  Widget addPaymentCard() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade300,
        ),
        child: const Center(
          child: Icon(Icons.add, size: 32),
        ),
      ),
    );
  }

  Widget transactionItem() {
    return ListTile(
      leading: const Icon(Icons.directions_car),
      title: const Text('Trip to Golden Gate Park'),
      subtitle: Text('June 17, 2025 - \$12.50'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }

  Widget promotionCard(String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {},
      ),
    );
  }
}