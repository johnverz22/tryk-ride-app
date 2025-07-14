import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class BannerCarousel extends StatelessWidget {
  final PageController controller;
  final List<String> images;

  const BannerCarousel({
    super.key,
    required this.controller,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 180,
            child: PageView.builder(
              controller: controller,
              itemCount: images.length,
              itemBuilder: (_, index) =>
                  Image.asset(images[index], fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SmoothPageIndicator(
          controller: controller,
          count: images.length,
          effect: ExpandingDotsEffect(
            dotHeight: 6,
            dotWidth: 6,
            spacing: 4,
            activeDotColor: theme.primaryColor,
            dotColor: Colors.grey.shade300,
          ),
        ),
      ],
    );
  }
}
