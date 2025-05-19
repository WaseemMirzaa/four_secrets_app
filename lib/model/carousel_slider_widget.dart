import 'package:four_secrets_wedding_app/model/carousel_slider_indicator.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class CarouselSliderWidget extends StatefulWidget {
  List<String> images;
  int activeIndex;
  double height;
  double viewportFraction;
  double enlargeFactor;

  CarouselSliderWidget(
      {super.key,
      required List<String> this.images,
      required int this.activeIndex,
      required double this.height,
      required double this.viewportFraction,
      required double this.enlargeFactor});

  @override
  State<CarouselSliderWidget> createState() => _CarouselSliderWidgetState();
}

class _CarouselSliderWidgetState extends State<CarouselSliderWidget> {
  Widget buildImage(
      BuildContext context, String image, int index, String mode) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5),
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.symmetric(horizontal: 5),
      child: Image.asset(
        image,
        fit: _BoxFitMode(mode),
      ),
    );
  }

  BoxFit? _BoxFitMode(String mode) {
    switch (mode) {
      case "cover":
        return BoxFit.cover;
      case "contain":
        return BoxFit.contain;
      case "fill":
        return BoxFit.fill;
      case "heiht":
        return BoxFit.fitHeight;
      case "width":
        return BoxFit.fitWidth;
      default:
        return BoxFit.contain;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 15,
        ),
        CarouselSlider.builder(
          itemCount: widget.images.length,
          itemBuilder: (context, index, realIndex) {
            final image = widget.images[index];
            return buildImage(context, image, index, "contain");
          },
          options: CarouselOptions(
            height: widget.height,
            initialPage: 0,
            pageSnapping: false,
            autoPlay: false,
            autoPlayInterval: const Duration(seconds: 2),
            viewportFraction: widget.viewportFraction,
            enlargeFactor: widget.enlargeFactor,
            enlargeCenterPage: true,
            enlargeStrategy: CenterPageEnlargeStrategy.scale,
            enableInfiniteScroll: false,
            onPageChanged: (index, reason) {
              setState(() => widget.activeIndex = index);
            },
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        CarouselSliderIndicatorWidget(
            images: widget.images, activeIndex: widget.activeIndex),
        const SizedBox(
          height: 5,
        ),
      ],
    );
  }
}
