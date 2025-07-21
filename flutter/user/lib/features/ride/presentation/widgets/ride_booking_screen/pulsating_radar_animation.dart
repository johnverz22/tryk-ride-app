// file: lib/features/ride/presentation/widgets/ride_booking_screen/pulsating_radar_animation.dart

import 'package:flutter/material.dart';

class PulsatingRadarAnimation extends StatefulWidget {
  final IconData icon;
  const PulsatingRadarAnimation({super.key, this.icon = Icons.directions_car});

  @override
  State<PulsatingRadarAnimation> createState() =>
      _PulsatingRadarAnimationState();
}

class _PulsatingRadarAnimationState extends State<PulsatingRadarAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);

    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: 150,
      child: CustomPaint(
        painter: RadarPainter(
          _animation,
          Theme.of(context).colorScheme.primary,
        ),
        child: Center(
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(widget.icon, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  final Animation<double> animation;
  final Color waveColor;

  RadarPainter(this.animation, this.waveColor) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTRB(0.0, 0.0, size.width, size.height);
    final center = rect.center;
    final radius = size.width / 2;

    for (int i = 3; i >= 0; i--) {
      final double waveRadius = radius * ((i + animation.value) / 4);
      final double opacity = 1.0 - (waveRadius / radius);

      final Paint wavePaint = Paint()
        ..color = waveColor.withAlpha((opacity.clamp(0.0, 1.0) * 255).toInt())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, waveRadius, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
