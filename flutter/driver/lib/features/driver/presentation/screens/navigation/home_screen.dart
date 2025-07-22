import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

import '../../widgets/widgets.dart';
import '../../providers/driver_provider.dart';
import '../../../data/models/ride_request_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  RideRequest? _selectedRide;
  Timer? _autoAcceptTimer;
  int _remainingSeconds = 30;
  AnimationController? _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _remainingSeconds),
    );
  }

  @override
  void dispose() {
    // THE FIX: Call the version of the cancellation method
    // that does NOT call setState.
    _cleanupTimerResources();
    _animationController?.dispose();
    super.dispose();
  }

  void _startAutoAcceptTimer(RideRequest ride) {
    // First, safely clean up any existing timer.
    _cleanupTimerResources();
    if (!mounted) return;

    setState(() {
      _remainingSeconds = 30;
      _selectedRide = ride;
    });

    _animationController?.duration = Duration(seconds: _remainingSeconds);
    _animationController?.forward(from: 0.0);

    _autoAcceptTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() => _remainingSeconds--);

      if (_remainingSeconds < 0) {
        // Since we are about to accept the ride, we can safely
        // call the full cancellation logic.
        _cancelAutoAcceptTimer();

        final updatedRide = await ref
            .read(driverProvider.notifier)
            .acceptRide(ride);

        if (!mounted) return;
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedRide != null
                  ? 'Ride auto-accepted.'
                  : 'Ride no longer available.',
            ),
            backgroundColor: updatedRide != null
                ? Colors.green
                : theme.colorScheme.error,
          ),
        );

        if (updatedRide != null) {
          await _showDriverConfirmationDialog(
            context: context,
            riderName: updatedRide.riderName ?? 'Rider',
            profilePicture: updatedRide.riderProfilePicture,
          );
        }
      }
    });
  }

  /// This version is safe to call from anywhere during the active lifecycle.
  void _cancelAutoAcceptTimer() {
    _cleanupTimerResources();
    if (mounted) {
      setState(() {
        _selectedRide = null;
      });
    }
  }

  /// THE FIX: A dedicated "safe" cleanup method that ONLY touches
  /// resources and never calls setState. This is what dispose will use.
  void _cleanupTimerResources() {
    _autoAcceptTimer?.cancel();
    _autoAcceptTimer = null;
    if (_animationController?.isAnimating ?? false) {
      _animationController?.stop();
    }
  }

  Future<void> _showDriverConfirmationDialog({
    required BuildContext context,
    required String riderName,
    required String? profilePicture,
  }) async {
    final theme = Theme.of(context);
    final result = await showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: PopScope(
            canPop: false,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.transparent,
                      child: Icon(Icons.check, color: Colors.white, size: 50),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Ride Accepted!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$riderName is waiting for you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundImage: (profilePicture?.isNotEmpty ?? false)
                            ? NetworkImage(profilePicture!)
                            : null,
                        backgroundColor: Colors.grey[300],
                        child: (profilePicture?.isEmpty ?? true)
                            ? const Icon(
                                Icons.person,
                                size: 36,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              riderName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: const [
                                Icon(Icons.star, color: Colors.amber, size: 20),
                                SizedBox(width: 4),
                                Text(
                                  '4.8 Rating',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pop('navigate_to_tracking'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('PROCEED TO PICKUP'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == 'navigate_to_tracking') {
      // TODO: Navigator.pushNamed(context, '/tracking');
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverStateAsync = ref.watch(driverProvider);
    final driverState = driverStateAsync.asData?.value;
    final rides = driverState?.requestedRides ?? [];
    final isOnline = driverState?.isOnline ?? false;

    final rideForTimer = rides.isNotEmpty ? rides.first : null;

    // Use a post-frame callback to safely start the timer after the build is complete.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (rideForTimer != null &&
          isOnline &&
          (_selectedRide == null || _selectedRide!.id != rideForTimer.id)) {
        _startAutoAcceptTimer(rideForTimer);
      } else if (_selectedRide != null &&
          (rideForTimer == null ||
              !rides.any((r) => r.id == _selectedRide!.id))) {
        _cancelAutoAcceptTimer();
      }
    });

    final selectedRideId = _selectedRide?.id;

    return Scaffold(
      appBar: const CustomUserAppBar(),
      backgroundColor: const Color(0xFFF5F5F5),
      body: rides.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.drive_eta_rounded,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isOnline
                          ? "Waiting for incoming ride requests..."
                          : "You are offline. Go online to receive rides.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rides.length,
              itemBuilder: (context, index) {
                final ride = rides[index];
                return _buildRideCard(context, ride, ride.id == selectedRideId);
              },
            ),
    );
  }

  String _formatAddress(String? fullAddress) {
    if (fullAddress == null || fullAddress.isEmpty) {
      return 'Unknown Location';
    }
    // Split the address by comma and trim whitespace from each part.
    final parts = fullAddress.split(',').map((p) => p.trim()).toList();

    // If there's only one part, return it as is.
    if (parts.length <= 1) {
      return parts.first;
    }

    // Otherwise, return the first two parts joined by a comma.
    // This typically represents the place name and the town/area.
    return '${parts[0]}, ${parts[1]}';
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String location,
    required Color labelColor,
    required Color locationColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: labelColor,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                location,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: locationColor,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRideCard(
    BuildContext context,
    RideRequest ride,
    bool isSelected,
  ) {
    final provider = ref.read(driverProvider.notifier);
    final theme = Theme.of(context);
    final textColor = isSelected ? Colors.white : Colors.black87;
    final subtextColor = isSelected
        ? Colors.white.withValues(alpha: 0.8)
        : Colors.grey[700];
    final iconColor = isSelected ? Colors.white : theme.primaryColor;

    final formattedPickup = _formatAddress(ride.pickupAddress);
    final formattedDropoff = _formatAddress(ride.dropoffAddress);

    return Card(
      elevation: isSelected ? 12 : 5,
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      shadowColor: isSelected
          ? theme.primaryColor.withValues(alpha: 0.4)
          : Colors.black.withValues(alpha: 0.08),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [theme.primaryColor, theme.colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFFDFDFD)],
                ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationRow(
                    icon: Icons.my_location,
                    iconColor: iconColor,
                    label: 'From',
                    location: formattedPickup,
                    labelColor: subtextColor!,
                    locationColor: textColor,
                  ),
                  Container(
                    height: 20,
                    margin: const EdgeInsets.only(left: 9, top: 4, bottom: 4),
                    width: 2,
                    color: iconColor.withValues(alpha: 0.3),
                  ),
                  _buildLocationRow(
                    icon: Icons.location_on,
                    iconColor: iconColor,
                    label: 'To',
                    location: formattedDropoff,
                    labelColor: subtextColor,
                    locationColor: textColor,
                  ),
                  const SizedBox(height: 20),
                  _buildKeyMetricsRow(ride, isSelected),
                  const SizedBox(height: 24),

                  // --- THE FIX IS HERE ---
                  SlideAction(
                    borderRadius: 16,
                    elevation: 0,
                    outerColor: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey[200],
                    innerColor: isSelected ? Colors.white : theme.primaryColor,
                    sliderButtonIcon: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 20,
                      color: isSelected ? theme.primaryColor : Colors.white,
                    ),
                    text: 'SLIDE TO ACCEPT',
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black54,
                      letterSpacing: 0.8,
                    ),
                    // REMOVED async/await. This is now "fire and forget".
                    onSubmit: () {
                      // Stop the timer immediately upon starting the accept action.
                      _cancelAutoAcceptTimer();

                      // Trigger the accept process but don't wait for it to finish.
                      // The UI will update via the Riverpod provider when the state changes.
                      provider.acceptRide(ride).then((updatedRide) {
                        if (!mounted) return;
                        if (updatedRide != null) {
                          _showDriverConfirmationDialog(
                            context: context,
                            riderName: updatedRide.riderName ?? 'Rider',
                            profilePicture: updatedRide.riderProfilePicture,
                          );
                        } else {
                          // The notifier already handled the state, but we can show a message.
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Ride was no longer available.',
                              ),
                              backgroundColor: theme.colorScheme.error,
                            ),
                          );
                        }
                      });
                      return null;

                      // By not returning a Future, the slide widget completes its animation
                      // immediately and doesn't wait for the provider logic.
                    },
                  ),
                ],
              ),
            ),

            if (isSelected) ...[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildAutoAcceptTimer(),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  tooltip: "Decline",
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.2),
                  ),
                  onPressed: () {
                    // Stop the timer when declining.
                    _cancelAutoAcceptTimer();
                    provider.rejectRide(ride).then((_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ride rejected.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    });
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetricsRow(RideRequest ride, bool isSelected) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildKeyMetricItem(
          icon: Icons.directions_car_filled_outlined,
          label: 'Distance',
          value: "${ride.distanceInKm?.toStringAsFixed(1) ?? '--'} km",
          isSelected: isSelected,
          isPrimary: true,
        ),
        _buildKeyMetricItem(
          icon: Icons.timer_outlined,
          label: 'Duration',
          value: "${ride.durationInMinutes?.toStringAsFixed(0) ?? '--'} min",
          isSelected: isSelected,
          isPrimary: true,
        ),
        _buildKeyMetricItem(
          icon: Icons.monetization_on_outlined,
          label: 'Fare',
          value: "₱${ride.fareAmount?.toStringAsFixed(2) ?? '--'}",
          isSelected: isSelected,
          isPrimary: true,
        ),
      ],
    );
  }

  // Add this new helper method too
  Widget _buildKeyMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isSelected,
    bool isPrimary = false,
  }) {
    final theme = Theme.of(context);
    final valueColor = isSelected
        ? Colors.white
        : isPrimary
        ? theme.primaryColor
        : Colors.black87;
    final labelColor = isSelected
        ? Colors.white.withValues(alpha: 0.8)
        : Colors.grey[600];
    final iconColor = isSelected
        ? Colors.white.withValues(alpha: 0.8)
        : isPrimary
        ? theme.primaryColor.withValues(alpha: 0.8)
        : Colors.grey[600];

    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: labelColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAutoAcceptTimer() {
    // This now just returns the visual progress bar.
    // We assume the _animationController is already running.
    return AnimatedBuilder(
      animation: _animationController!,
      builder: (context, child) {
        return LinearProgressIndicator(
          value: 1.0 - _animationController!.value,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          color: Colors.white,
          minHeight: 5,
        );
      },
    );
  }
}

class TimerPainter extends CustomPainter {
  final Animation<double> animation;
  final Color backgroundColor, color;

  TimerPainter({
    required this.animation,
    required this.backgroundColor,
    required this.color,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(size.center(Offset.zero), size.width / 2.0, paint);
    paint.color = color;
    double progress = (1.0 - animation.value) * 2 * 3.1415926535897932;
    canvas.drawArc(
      Offset.zero & size,
      vector.radians(-90),
      -progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(TimerPainter oldDelegate) {
    return animation.value != oldDelegate.animation.value ||
        color != oldDelegate.color ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
