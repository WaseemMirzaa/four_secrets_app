// Do we need this in future?

// import 'package:flutter/material.dart';

// // ignore: must_be_immutable
// class CarouselSliderWidget extends StatelessWidget {
//   List<String> images;
//   double height;

//   CarouselSliderWidget({
//     super.key,
//     required this.images,
//     required this.height,
//   });

//   Widget buildImage(
//       BuildContext context, String image, int index, String mode) {
//     return Container(
//       width: MediaQuery.of(context).size.width,
//       margin: const EdgeInsets.symmetric(horizontal: 5),
//       child: Image.asset(
//         image,
//         fit: _BoxFitMode(mode),
//         filterQuality: FilterQuality.medium,
//       ),
//     );
//   }

//   BoxFit? _BoxFitMode(String mode) {
//     switch (mode) {
//       case "cover":
//         return BoxFit.cover;
//       case "contain":
//         return BoxFit.contain;
//       case "fill":
//         return BoxFit.fill;
//       case "height":
//         return BoxFit.fitHeight;
//       case "width":
//         return BoxFit.fitWidth;
//       default:
//         return BoxFit.contain;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: height,
//       child: CardSwiper(
//         cardsCount: images.length,
//         cardBuilder: (context, index, percentThresholdX, percentThresholdY) =>
//             buildImage(context, images[index], index, "contain"),
//       ),
//     );
//   }
// }
