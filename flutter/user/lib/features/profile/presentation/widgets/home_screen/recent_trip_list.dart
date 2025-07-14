// import 'package:flutter/material.dart';
// import 'package:user/config/currency.dart';
// import 'package:user/features/ride/presentation/screens/ride_booking_screen.dart';
// import '../../pages/screens/navigation/home/ride_booking_screen.dart';
// import '../../pages/screens/navigation/home/ride_tracking_screen.dart';
// import '../../providers/trip_provider.dart';

// class RecentTripList extends StatelessWidget {
//   final Future<List<Trip>>? futureTrips;

//   const RecentTripList({super.key, required this.futureTrips});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return FutureBuilder<List<Trip>>(
//       future: futureTrips,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(
//             child: Padding(
//               padding: EdgeInsets.all(16),
//               child: CircularProgressIndicator(),
//             ),
//           );
//         }

//         if (snapshot.hasError) {
//           return const Center(
//             child: Text('Failed to load trips. Please try again.'),
//           );
//         }

//         if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return Column(
//             children: [
//               const Icon(
//                 Icons.directions_car_filled_outlined,
//                 size: 60,
//                 color: Colors.grey,
//               ),
//               const SizedBox(height: 10),
//               const Text('No ongoing trips right now.'),
//               const SizedBox(height: 10),
//               ElevatedButton.icon(
//                 onPressed: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => const RideBookingScreen()),
//                 ),
//                 icon: const Icon(Icons.add),
//                 label: const Text('Book Your First Ride'),
//               ),
//             ],
//           );
//         }

//         final trips = snapshot.data!.take(3).toList();
//         return Column(
//           children: trips.map((trip) {
//             return Card(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               elevation: 2,
//               margin: const EdgeInsets.only(bottom: 14),
//               child: ListTile(
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 12,
//                 ),
//                 leading: CircleAvatar(
//                   radius: 22,
//                   backgroundColor: theme.primaryColor.withOpacity(0.1),
//                   child: Icon(Icons.directions_car, color: theme.primaryColor),
//                 ),
//                 title: Text(
//                   trip.pickup_address,
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Text(
//                   trip.dropoff_address,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(color: Colors.grey),
//                 ),
//                 trailing: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       currencyFormatter.format({trip.price.toStringAsFixed(2)}),
//                       style: const TextStyle(
//                         color: Colors.green,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(Icons.star, size: 14, color: Colors.amber),
//                         const SizedBox(width: 2),
//                         Text(
//                           trip.rating > 0
//                               ? trip.rating.toStringAsFixed(1)
//                               : 'N/A',
//                           style: const TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//                 onTap: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) =>
//                         RideTrackingScreen(rideId: int.tryParse(trip.id)),
//                   ),
//                 ),
//               ),
//             );
//           }).toList(),
//         );
//       },
//     );
//   }
// }
