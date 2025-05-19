import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// ignore: must_be_immutable
class CarouselSliderIndicatorWidget extends StatelessWidget {
  List<String> images;
  int activeIndex;

  CarouselSliderIndicatorWidget(
      {super.key,
      required List<String> this.images,
      required int this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, top: 5),
      child: AnimatedSmoothIndicator(
        activeIndex: activeIndex,
        count: images.length,
        effect: SlideEffect(
          dotWidth: 16,
          dotHeight: 16,
          dotColor: Colors.grey.shade400,
          activeDotColor: Colors.grey.shade700,
          type: SlideType.normal,
        ),
      ),
    );
  }
}
