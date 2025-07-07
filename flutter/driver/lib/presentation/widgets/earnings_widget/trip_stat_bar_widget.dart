import 'package:flutter/material.dart';
import 'earnings_widgets.dart';

class TripStatBarWidget extends StatelessWidget {
  const TripStatBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          TripStatTile(label: 'Trips', value: '42'),
          TripStatTile(label: 'Online Hours', value: '21.3'),
          TripStatTile(label: 'Avg Rating', value: '4.92'),
        ],
    );
  }
}