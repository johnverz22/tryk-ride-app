import './overlay_earnings_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OverlayEntryWidget extends ConsumerWidget {
  const OverlayEntryWidget({super.key});

  final double cardHeight = 300;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PageController pageController = PageController(
      initialPage: 1,
      keepPage: false,
    );

    return Container(
      padding: const EdgeInsets.only(top: 120),
      height: double.infinity,
      color: Colors.black.withAlpha(128),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: pageController,
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: EarningsCard(cardHeight: cardHeight),
                          ),
                        ),
                      ],
                    ); // Replace with your actual card widget
                  },
                ),
              ),
            ],
          ),
          Positioned(
            top: cardHeight + 10,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: pageController,
                count: 3,
                effect: WormEffect(
                  dotHeight: 15,
                  dotWidth: 15,
                  activeDotColor: Colors.white,
                  dotColor: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
