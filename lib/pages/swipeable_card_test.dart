import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/model/swipeable_card_widget.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';

class SwipeableCardTest extends StatefulWidget {
  const SwipeableCardTest({Key? key}) : super(key: key);

  @override
  _SwipeableCardTestState createState() => _SwipeableCardTestState();
}

class _SwipeableCardTestState extends State<SwipeableCardTest> {
  // Test images
  final List<String> testImages = [
    "assets/images/background/hairstyling_makeup_back.jpg",
    "assets/images/background/band_back.jpg",
    "assets/images/background/location_back.jpg",
    "assets/images/background/wedding_design_back.jpg",
  ];

  final Key key = GlobalKey<MenueState>();

  // Settings for the swipeable card
  String selectedFitMode = "contain";
  bool showIndicators = true;
  bool showSwipeHints = true;
  double cardHeight = 400;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue.getInstance(key),
        appBar: AppBar(
          foregroundColor: Colors.white,
          title: const Text('Swipeable Card Test'),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        ),
        body: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              opacity: 0.25,
              image: AssetImage("assets/images/background/location_back.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: SingleChildScrollView(
            physics: ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Swipeable Card Widget
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: SwipeableCardWidget(
                    images: testImages,
                    height: cardHeight,
                    imageFit: selectedFitMode,
                    showIndicators: showIndicators,
                    showSwipeHints: showSwipeHints,
                  ),
                ),

                FourSecretsDivider(),

                // Controls
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Card Settings",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Image Fit Mode
                      Text("Image Fit Mode:"),
                      DropdownButton<String>(
                        value: selectedFitMode,
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedFitMode = newValue!;
                          });
                        },
                        items: <String>[
                          'contain',
                          'cover',
                          'fill',
                          'height',
                          'width',
                          'scaleDown',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Show Indicators
                      Row(
                        children: [
                          Text("Show Indicators:"),
                          Switch(
                            value: showIndicators,
                            onChanged: (value) {
                              setState(() {
                                showIndicators = value;
                              });
                            },
                          ),
                        ],
                      ),

                      // Show Swipe Hints
                      Row(
                        children: [
                          Text("Show Swipe Hints:"),
                          Switch(
                            value: showSwipeHints,
                            onChanged: (value) {
                              setState(() {
                                showSwipeHints = value;
                              });
                            },
                          ),
                        ],
                      ),

                      // Card Height
                      Text("Card Height: ${cardHeight.toInt()}"),
                      Slider(
                        value: cardHeight,
                        min: 200,
                        max: 600,
                        divisions: 8,
                        onChanged: (value) {
                          setState(() {
                            cardHeight = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                FourSecretsDivider(),

                // Instructions
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Instructions",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "• Swipe left or right to change images\n"
                        "• Even a small swipe will trigger the change\n"
                        "• Quick flick gestures also work\n"
                        "• Images have rounded corners\n"
                        "• Dots at the bottom show current position\n"
                        "• Visual feedback shows swipe direction",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
