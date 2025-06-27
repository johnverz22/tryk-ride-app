import 'package:driver/features/skeleton/widgets/earnings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/driver_provider.dart'; // Adjust the import path accordingly

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverState = ref.watch(driverProvider);

    return Container(
      color: Color(0xFFFBF5DF), // Background color
      child: Stack(
        children: [
          Center(
            child: EarningsCard(cardHeight: 300,),
            // child: Text(
            //   'B A N A N A',
            //   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.yellow[600]),
            // ),
          ),
          Positioned(
              left: 20,
              bottom: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Floating Button
                  FloatingActionButton(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50), // Adjust the rounding
                  ),
                    onPressed: () {
                    },
                    child: Icon(Icons.add),
                  ),
                  SizedBox(height: 20), // Space between buttons
                  // Bottom Floating Button
                  FloatingActionButton(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50), // Adjust the rounding
                  ),
                    onPressed: () {
                    },
                    child: Icon(Icons.add),
                  ),
                ],
              ),
            ),
          Positioned(
            right: 20,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Floating Button
                FloatingActionButton(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50), // Adjust the rounding
                  ),
                  onPressed: () {
                  },
                  child: Icon(Icons.add),
                ),
                SizedBox(height: 20), // Space between buttons
                // Bottom Floating Button
                FloatingActionButton(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50), // Adjust the rounding
                  ),
                  onPressed: () {
                  },
                  child: Icon(Icons.add),
                ),
              ],
            ),
          ),
        
        ],
      ),
    );
  }
}