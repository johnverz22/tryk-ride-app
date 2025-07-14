// import 'dart:convert';
// import 'dart:math';
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;
// import 'package:permission_handler/permission_handler.dart';
// import 'package:user/features/profile/presentation/providers/payment_info_provider.dart';

// import '../../../../../../../core/services/auth_service.dart';
// import '../../../../widgets/widgets.dart';

// class RideBookingScreen extends ConsumerStatefulWidget {
//   const RideBookingScreen({super.key});

//   @override
//   ConsumerState<RideBookingScreen> createState() => _RideBookingScreenState();
// }

// class _RideBookingScreenState extends ConsumerState<RideBookingScreen> {
//   final TextEditingController _fromController = TextEditingController();
//   final TextEditingController _toController = TextEditingController();
//   String? baseUrl = dotenv.env['BASE_URL'];
//   String? googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
//   LatLng? _fromLocation;
//   LatLng? _toLocation;
//   String _selectedPaymentMethod = 'Cash';
//   double _searchRadiusKm = 10;
//   bool _isLoading = false;
//   bool _rideCancelled = false;
//   bool _isBottomSheetOpen = false;
//   Timer? _statusCheckTimer;

//   double? _routeDistanceMeters;
//   int? _routeDurationSeconds;
//   int? _rideId;
//   double? _distance;
//   double? _fare;
//   double? _duration;
//   static const int requestedStatusId = 1;

//   @override
//   void initState() {
//     super.initState();
//     _ensureLocationPermission();
//   }

//   Future<void> _ensureLocationPermission() async {
//     final status = await Permission.locationWhenInUse.request();
//     if (!status.isGranted) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Location permission is required.')),
//         );
//       }
//     }
//   }

//   Future<void> _fetchRouteInfo() async {
//     if (_fromLocation == null ||
//         _toLocation == null ||
//         googleMapsApiKey == null) {
//       return;
//     }

//     final url =
//         'https://maps.googleapis.com/maps/api/directions/json?origin=${_fromLocation!.latitude},${_fromLocation!.longitude}&destination=${_toLocation!.latitude},${_toLocation!.longitude}&key=$googleMapsApiKey';

//     try {
//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
//           final leg = data['routes'][0]['legs'][0];
//           setState(() {
//             _routeDistanceMeters = (leg['distance']['value'] as num).toDouble();
//             _routeDurationSeconds = (leg['duration']['value'] as num).toInt();
//           });
//         }
//       }
//     } catch (e) {
//       // Optionally handle error
//     }
//   }

//   Future<void> _checkRideStatusPeriodically() async {
//     final token = await AuthService().getToken();
//     if (token == null || _rideId == null) return;

//     _statusCheckTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
//       if (!mounted) {
//         timer.cancel();
//         return;
//       }

//       try {
//         final uri = Uri.parse('$baseUrl/rides/$_rideId');
//         final response = await http.get(
//           uri,
//           headers: {
//             'Authorization': 'Bearer $token',
//             'Content-Type': 'application/json',
//           },
//         );

//         if (response.statusCode == 200) {
//           final ride = jsonDecode(response.body);
//           final statusId = ride['ride_status_id'];

//           if (statusId == 2 && ride['driver'] != null) {
//             timer.cancel();
//             _statusCheckTimer = null;

//             if (_isBottomSheetOpen && mounted) {
//               Navigator.of(context, rootNavigator: true).pop();
//               _isBottomSheetOpen = false;
//               await Future.delayed(const Duration(milliseconds: 300));
//             }

//             if (mounted) {
//               final driver = ride['driver'];
//               final profilePicture = driver['profile_picture'];
//               final vehicle = driver['vehicle'] ?? 'Toyota Vios';
//               final driverName = driver['name'];

//               await _showDriverConfirmedModal(
//                 driverName,
//                 profilePicture,
//                 vehicle,
//               );
//             }
//           }
//         }
//       } catch (e) {
//         print('Error polling ride status: $e');
//       }
//     });
//   }

//   // New separate method to handle the driver confirmed modal
//   Future<void> _showDriverConfirmedModal(
//     String driverName,
//     String? profilePicture,
//     String vehicle,
//   ) async {
//     if (_isBottomSheetOpen) return; // Prevent multiple modals
//     _isBottomSheetOpen = true;

//     final result = await showModalBottomSheet<String?>(
//       context: context,
//       isScrollControlled: true,
//       isDismissible: false, // Prevent dismissing by tapping outside
//       enableDrag: false, // Prevent dismissing by dragging
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       backgroundColor: Colors.white,
//       builder: (bottomSheetContext) {
//         return PopScope(
//           canPop: false,
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 const Icon(
//                   Icons.emoji_transportation,
//                   size: 48,
//                   color: Colors.green,
//                 ),
//                 const SizedBox(height: 16),
//                 const Text(
//                   'Driver Confirmed!',
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.w700,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   '$driverName is on the way to pick you up!',
//                   style: TextStyle(fontSize: 16, color: Colors.grey[700]),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 36,
//                       backgroundImage:
//                           profilePicture != null && profilePicture.isNotEmpty
//                           ? NetworkImage(profilePicture)
//                           : null,
//                       backgroundColor: Colors.grey[300],
//                       child: (profilePicture == null || profilePicture.isEmpty)
//                           ? const Icon(
//                               Icons.person,
//                               size: 36,
//                               color: Colors.white,
//                             )
//                           : null,
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             driverName,
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           const Row(
//                             children: [
//                               Icon(Icons.star, color: Colors.amber, size: 16),
//                               SizedBox(width: 4),
//                               Text('4.8'),
//                             ],
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'Vehicle: $vehicle',
//                             style: TextStyle(color: Colors.grey[600]),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 32),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     icon: const Icon(Icons.verified),
//                     label: const Text('Great, thanks!'),
//                     onPressed: () {
//                       Navigator.of(
//                         bottomSheetContext,
//                       ).pop('navigate_to_tracking');
//                     },
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       backgroundColor: Colors.green[600],
//                       foregroundColor: Colors.white,
//                       textStyle: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );

//     _isBottomSheetOpen = false;

//     if (!mounted) return;

//     print('Driver confirmed modal result: $result');
//   }

//   Future<void> _showSearchingBottomSheet() async {
//     _isBottomSheetOpen = true;
//     setState(() => _rideCancelled = false);

//     await showModalBottomSheet<void>(
//       context: context,
//       isScrollControlled: true,
//       enableDrag: false,
//       isDismissible: false,
//       backgroundColor: Colors.transparent,
//       builder: (_) {
//         return SearchingDriverBottomSheet(
//           baseUrl: baseUrl,
//           rideId: _rideId,
//           onCancelled: () {
//             if (mounted) {
//               setState(() {
//                 _rideId = null;
//                 _isBottomSheetOpen = false;
//               });
//             }
//           },
//           cancelStatusCheck: () {
//             _statusCheckTimer?.cancel();
//             _statusCheckTimer = null;
//           },
//         );
//       },
//     );

//     _isBottomSheetOpen = false;
//   }

//   // New separate method to handle the driver confirmed modal

//   Future<void> _requestRide() async {
//     if (_fromLocation == null || _toLocation == null) return;

//     final now = DateTime.now().toIso8601String();

//     final uri = Uri.parse('$baseUrl/rides/request');
//     final token = await AuthService().getToken();

//     if (token == null) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('You must be logged in.')));
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       final response = await http.post(
//         uri,
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({
//           'pickup_address': _fromController.text,
//           'pickup_latitude': _fromLocation!.latitude,
//           'pickup_longitude': _fromLocation!.longitude,
//           'dropoff_address': _toController.text,
//           'dropoff_latitude': _toLocation!.latitude,
//           'dropoff_longitude': _toLocation!.longitude,
//           'requested_at': now,
//           'distance_km': _distance,
//           'duration_minutes': _duration,
//           'fare_amount': _fare,
//           'ride_status_id': requestedStatusId,
//           'payment_method': _selectedPaymentMethod,
//           'search_radius_km': _searchRadiusKm.round(),
//         }),
//       );

//       if (!mounted) return;

//       if (response.statusCode == 201 || response.statusCode == 200) {
//         final responseData = jsonDecode(response.body);
//         setState(() {
//           _rideId = responseData['ride']['id'];
//         });

//         _checkRideStatusPeriodically();
//         await _showSearchingBottomSheet();

//         if (mounted && !_rideCancelled) {
//           Navigator.of(context, rootNavigator: true).pop();
//         }
//       } else {
//         final error = jsonDecode(response.body)['message'] ?? response.body;
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Request failed: $error')));
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   double _calculateDistanceKm(
//     double lat1,
//     double lon1,
//     double lat2,
//     double lon2,
//   ) {
//     const double earthRadius = 6371;
//     final double dLat = _degToRad(lat2 - lat1);
//     final double dLon = _degToRad(lon2 - lon1);

//     final double a =
//         (sin(dLat / 2) * sin(dLat / 2)) +
//         cos(_degToRad(lat1)) *
//             cos(_degToRad(lat2)) *
//             (sin(dLon / 2) * sin(dLon / 2));

//     final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
//     return earthRadius * c;
//   }

//   double _degToRad(double deg) => deg * pi / 180;

//   void _handlePayment() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Simulated ride fare amount
//       final double fareAmount = _fare ?? 0;

//       // Step 1: Authorize payment (simulate Maya Vault + wallet interaction)
//       final bool paymentAuthorized = await _simulatePaymentAuthorization(
//         fareAmount,
//       );

//       if (paymentAuthorized) {
//         // Payment frozen, proceed with ride request
//         _requestRide();
//       } else {
//         // Show error - failed to authorize
//         _showError('Payment authorization failed. Please try again.');
//       }
//     } catch (e) {
//       _showError('Something went wrong. Please try again.');
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<bool> _simulatePaymentAuthorization(double amount) async {
//     // Simulate a network/API call delay
//     await Future.delayed(const Duration(seconds: 2));

//     // Simulate a successful payment authorization
//     return true;
//   }

//   void _showError(String message) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(message)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final walletAsync = ref.watch(paymentInfoProvider);
//     final theme = Theme.of(context);
//     final color = theme.colorScheme;

//     final hasRouteInfo =
//         _routeDistanceMeters != null && _routeDurationSeconds != null;

//     final totalDistance = hasRouteInfo
//         ? _routeDistanceMeters! / 1000
//         : (_fromLocation != null && _toLocation != null)
//         ? _calculateDistanceKm(
//             _fromLocation!.latitude,
//             _fromLocation!.longitude,
//             _toLocation!.latitude,
//             _toLocation!.longitude,
//           )
//         : null;

//     final canRequestRide =
//         _fromLocation != null && _toLocation != null && !_isLoading;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Book a Ride'),
//         backgroundColor: theme.colorScheme.primary,
//         foregroundColor: theme.colorScheme.onPrimary,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withValues(alpha: .05),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//                 border: Border.all(color: Colors.grey[200]!),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.route,
//                         color: Theme.of(context).colorScheme.primary,
//                         size: 24,
//                       ),
//                       const SizedBox(width: 10),
//                       Text(
//                         'Plan Your Trip',
//                         style: Theme.of(context).textTheme.titleMedium
//                             ?.copyWith(fontWeight: FontWeight.w600),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),

//                   /// Pickup Location
//                   LocationSelector(
//                     label: 'Pickup Location',
//                     icon: Icons.my_location,
//                     controller: _fromController,
//                     onLocationPicked: (picked) async {
//                       final loc = picked['latLng'];
//                       final desc = picked['description'];
//                       setState(() {
//                         _fromLocation = loc;
//                         _fromController.text = desc;
//                         _routeDistanceMeters = null;
//                         _routeDurationSeconds = null;
//                       });
//                       await _fetchRouteInfo();
//                     },
//                     onClear: () => setState(() {
//                       _fromController.clear();
//                       _fromLocation = null;
//                     }),
//                   ),
//                   const SizedBox(height: 16),

//                   /// Destination
//                   LocationSelector(
//                     label: 'Destination',
//                     icon: Icons.location_on,
//                     controller: _toController,
//                     onLocationPicked: (picked) async {
//                       final loc = picked['latLng'];
//                       final desc = picked['description'];
//                       setState(() {
//                         _toLocation = loc;
//                         _toController.text = desc;
//                         _routeDistanceMeters = null;
//                         _routeDurationSeconds = null;
//                       });
//                       await _fetchRouteInfo();
//                     },
//                     onClear: () => setState(() {
//                       _toController.clear();
//                       _toLocation = null;
//                     }),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),

//             /// Payment Method
//             walletAsync.when(
//               data: (paymentInfo) => PaymentMethodCard(
//                 selectedMethod: _selectedPaymentMethod,
//                 onSelect: (method) =>
//                     setState(() => _selectedPaymentMethod = method),
//               ),
//               loading: () => const Center(child: CircularProgressIndicator()),
//               error: (error, stack) =>
//                   const Center(child: Text('Failed to load wallet')),
//             ),

//             /// Route Preview
//             if (_fromLocation != null &&
//                 _toLocation != null &&
//                 totalDistance != null)
//               RoutePreviewSection(
//                 from: _fromLocation!,
//                 to: _toLocation!,
//                 distanceInKm: _routeDistanceMeters != null
//                     ? _routeDistanceMeters! / 1000
//                     : null,
//                 durationInMinutes: _routeDurationSeconds != null
//                     ? _routeDurationSeconds! / 60
//                     : null,
//                 onRouteInfoLoaded: (distanceKm, durationMin, fare) {
//                   setState(() {
//                     _distance = distanceKm;
//                     _duration = durationMin;
//                     _fare = fare;
//                   });
//                 },
//               ),

//             const SizedBox(height: 20),

//             /// Search Radius
//             DriverSearchRadiusSlider(
//               radiusKm: _searchRadiusKm,
//               onChanged: (value) => setState(() => _searchRadiusKm = value),
//             ),

//             const SizedBox(height: 20),

//             /// Request Button
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 onPressed: canRequestRide ? _handlePayment : null,
//                 icon: _isLoading
//                     ? const SizedBox(
//                         width: 16,
//                         height: 16,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: Colors.white,
//                         ),
//                       )
//                     : const Icon(Icons.local_taxi),
//                 label: Text(_isLoading ? 'Requesting...' : 'Request Ride'),
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   textStyle: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                   backgroundColor: color.primary,
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _statusCheckTimer?.cancel();
//     _fromController.dispose();
//     _toController.dispose();
//     super.dispose();
//   }
// }
