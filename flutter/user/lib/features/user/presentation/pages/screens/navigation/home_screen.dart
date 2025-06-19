import 'package:flutter/material.dart';
import '../ride_booking_screen.dart';
import '../../../widgets/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomUserAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Where are you going?',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          const LocationCard(
            icon: Icons.my_location,
            title: '123 Main Street, San Francisco',
            subtitle: 'Current Location',
          ),
          const SizedBox(height: 12),
          const LocationCard(
            icon: Icons.location_on_outlined,
            title: '123 Main Street, San Francisco',
            subtitle: 'Enter destination',
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved Places',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'See All',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              PlaceChip(label: 'Home', icon: Icons.home),
              PlaceChip(label: 'Work', icon: Icons.work),
              PlaceChip(label: 'Favorite Cafe', icon: Icons.local_cafe),
              PlaceChip(label: 'Mall', icon: Icons.store),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Trips',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'See All',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const RecentTripTile(
            title: 'Golden Gate Park',
            subtitle: '501 Stanyan St, San Francisco',
          ),
          const RecentTripTile(
            title: 'Union Square',
            subtitle: '333 Post St, San Francisco',
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RideBookingScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
            ),
            child: const Text(
              'Search Rides',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
