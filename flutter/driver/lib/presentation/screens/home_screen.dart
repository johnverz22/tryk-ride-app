import 'package:driver/presentation/widgets/overlay_earnings_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Container(
      color: Color(0xFFFBF5DF), // Background color
      child: Stack(
        children: [
          Center(child: EarningsCard(cardHeight: 300),),
          // GoogleMap(
          //   initialCameraPosition: CameraPosition(
          //     target: LatLng(45.521563, -122.677433), // Example: Manila
          //     zoom: 14,
          //   ),
          // ),
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