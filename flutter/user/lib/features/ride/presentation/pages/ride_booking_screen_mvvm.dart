import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/ride_booking_viewmodel.dart';
import '../../business/entities/ride_entity.dart';
import '../../business/entities/driver_entity.dart';

class RideBookingScreenMVVM extends StatefulWidget {
  const RideBookingScreenMVVM({super.key});

  @override
  State<RideBookingScreenMVVM> createState() => _RideBookingScreenMVVMState();
}

class _RideBookingScreenMVVMState extends State<RideBookingScreenMVVM> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RideBookingViewModel>().loadNearbyDrivers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Ride'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Consumer<RideBookingViewModel>(
        builder: (context, viewModel, child) {
          return _buildBody(context, viewModel);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, RideBookingViewModel viewModel) {
    switch (viewModel.state) {
      case BookingState.initial:
      case BookingState.loadingDrivers:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Finding nearby drivers...'),
            ],
          ),
        );

      case BookingState.driversLoaded:
        return _buildRideOptions(context, viewModel);

      case BookingState.requestingRide:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Requesting your ride...'),
            ],
          ),
        );

      case BookingState.rideRequested:
      case BookingState.waitingForDriver:
        return _buildWaitingForDriver(context, viewModel);

      case BookingState.driverAccepted:
      case BookingState.driverEnRoute:
        return _buildDriverEnRoute(context, viewModel);

      case BookingState.driverArrived:
        return _buildDriverArrived(context, viewModel);

      case BookingState.rideInProgress:
        return _buildRideInProgress(context, viewModel);

      case BookingState.rideCompleted:
        return _buildRideCompleted(context, viewModel);

      case BookingState.rideCancelled:
        return _buildRideCancelled(context, viewModel);

      case BookingState.error:
        return _buildError(context, viewModel);

      default:
        return const Center(child: Text('Unknown state'));
    }
  }

  Widget _buildRideOptions(BuildContext context, RideBookingViewModel viewModel) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Location summary
        _buildLocationSummary(viewModel),
        const SizedBox(height: 16),

        // Available drivers count
        Text(
          '${viewModel.nearbyDrivers.length} drivers nearby',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),

        // Ride type options
        _buildRideTypeOption(
          context,
          viewModel,
          RideType.economy,
          'Economy',
          '\$12.50',
          '4 seats • 5 min away',
          Icons.directions_car,
        ),
        _buildRideTypeOption(
          context,
          viewModel,
          RideType.comfort,
          'Comfort',
          '\$18.75',
          '4 seats • 8 min away',
          Icons.car_rental,
        ),
        _buildRideTypeOption(
          context,
          viewModel,
          RideType.premium,
          'Premium',
          '\$25.00',
          '4 seats • 3 min away',
          Icons.directions_car_filled,
        ),

        const SizedBox(height: 24),

        // Payment method
        const Row(
          children: [
            Icon(Icons.credit_card),
            SizedBox(width: 8),
            Text('•••• 4582'),
          ],
        ),

        const SizedBox(height: 24),

        // Request button
        ElevatedButton(
          onPressed: viewModel.hasValidLocations
              ? () => viewModel.requestRide()
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            minimumSize: const Size.fromHeight(50),
          ),
          child: Text(
            'Request ${_getRideTypeName(viewModel.selectedRideType)}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSummary(RideBookingViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    viewModel.pickupAddress ?? 'Set pickup location',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.flag, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    viewModel.dropoffAddress ?? 'Set destination',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideTypeOption(
    BuildContext context,
    RideBookingViewModel viewModel,
    RideType rideType,
    String title,
    String price,
    String details,
    IconData icon,
  ) {
    final isSelected = viewModel.selectedRideType == rideType;
    
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.indigo.shade50 : Colors.white,
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.indigo : Colors.grey),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(details),
        trailing: Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        onTap: () => viewModel.setRideType(rideType),
      ),
    );
  }

  Widget _buildWaitingForDriver(BuildContext context, RideBookingViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Looking for a driver...',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Text('We\'re finding the best driver for your trip'),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Cancel ride logic
              viewModel.resetBooking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverEnRoute(BuildContext context, RideBookingViewModel viewModel) {
    final ride = viewModel.currentRide!;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Driver info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: viewModel.assignedDriver?.profilePhotoUrl != null
                            ? NetworkImage(viewModel.assignedDriver!.profilePhotoUrl!)
                            : null,
                        child: viewModel.assignedDriver?.profilePhotoUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              viewModel.assignedDriver?.name ?? 'Driver',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                Text('${viewModel.assignedDriver?.rating ?? 5.0}'),
                                const SizedBox(width: 8),
                                Text('${viewModel.assignedDriver?.totalTrips ?? 0} trips'),
                              ],
                            ),
                            Text(viewModel.assignedDriver?.vehicleInfo ?? 'Vehicle'),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            onPressed: () {
                              // Call driver
                            },
                            icon: const Icon(Icons.phone),
                          ),
                          IconButton(
                            onPressed: () {
                              // Message driver
                            },
                            icon: const Icon(Icons.message),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Status and ETA
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    ride.status == RideStatus.accepted
                        ? 'Driver is on the way'
                        : 'Driver is arriving',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ETA: ${ride.estimatedArrivalMinutes ?? 5} minutes',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Cancel button
          ElevatedButton(
            onPressed: () {
              // Cancel ride logic
              viewModel.resetBooking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Cancel Ride'),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverArrived(BuildContext context, RideBookingViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_on,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          Text(
            'Your driver has arrived!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Text('Please meet your driver at the pickup location'),
        ],
      ),
    );
  }

  Widget _buildRideInProgress(BuildContext context, RideBookingViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.directions_car,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          Text(
            'Enjoy your ride!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Text('You\'re on your way to your destination'),
        ],
      ),
    );
  }

  Widget _buildRideCompleted(BuildContext context, RideBookingViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          Text(
            'Trip completed!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Text('Thank you for riding with us'),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              viewModel.resetBooking();
              Navigator.of(context).pop();
            },
            child: const Text('Book Another Ride'),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCancelled(BuildContext context, RideBookingViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cancel,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 24),
          Text(
            'Ride cancelled',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Text('Your ride has been cancelled'),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              viewModel.resetBooking();
            },
            child: const Text('Book New Ride'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, RideBookingViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 24),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(viewModel.errorMessage ?? 'An unexpected error occurred'),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              viewModel.resetBooking();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  String _getRideTypeName(RideType rideType) {
    switch (rideType) {
      case RideType.economy:
        return 'Economy';
      case RideType.comfort:
        return 'Comfort';
      case RideType.premium:
        return 'Premium';
    }
  }
}