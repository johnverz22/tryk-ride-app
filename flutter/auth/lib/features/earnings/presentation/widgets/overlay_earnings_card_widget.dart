import 'package:flutter/material.dart';

class EarningsCard extends StatelessWidget {
  final double cardHeight;
  const EarningsCard({super.key, required this.cardHeight});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cardHeight,
      width: 300,
      child: Card(
        color: Color(0xFFFCFCF7), // Background color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              IconButton(
                padding: EdgeInsets.only(bottom: 20),
                onPressed: () {},
                icon: Icon(Icons.visibility, color: Colors.black),
              ),
              Text(
                'LAST TRIP',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),
              Text(
                "Aug 26 at 10:30 AM",
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
              Text(
                'Standard Trip',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
              Spacer(),
              TextButton(
                onPressed: () {},
                child: Text(
                  'SEE EARNINGS ACTIVITY',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
