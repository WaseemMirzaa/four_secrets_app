import 'package:DreamWedding/data/bachelorette_data.dart';
import 'package:DreamWedding/data/bachelorette_images.dart';
import 'package:DreamWedding/model/carousel_slider_widget.dart';
import 'package:DreamWedding/model/footer_buttons.dart';
import 'package:DreamWedding/model/four_secrets_divider.dart';
import 'package:flutter/material.dart';
import 'package:DreamWedding/menue.dart';
import 'package:DreamWedding/data/bachelorette_card_items.dart';

// // ignore: must_be_immutable
// ignore: must_be_immutable
class BacheloretteParty extends StatelessWidget {
  BacheloretteParty({super.key});

  late List<String> images = BacheloretteImages.getImages();
  final List items = BacheloretteCardItems.getCardItems();

  var urlHomepage = BacheloretteData.map["homepage"] != null
      ? BacheloretteData.map["homepage"]!
      : "";

  var urlInstagram = BacheloretteData.map["instagram"] != null
      ? BacheloretteData.map["instagram"]!
      : "";

  var mailAdress = BacheloretteData.map["email"] != null
      ? BacheloretteData.map["email"]!
      : "";

  var videoAsset = BacheloretteData.map["videoAsset"] != null
      ? BacheloretteData.map["videoAsset"]!
      : "";

  var videoUri = BacheloretteData.map["videoUri"] != null
      ? BacheloretteData.map["videoUri"]!
      : "";

  var videoRatio = BacheloretteData.map["videoRatio"] != null
      ? BacheloretteData.map["videoRatio"]!
      : "";

  int activeIndex = 0;
  String urlMode = "default";

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: const Menue(),
        appBar: AppBar(
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          title: const Text('Bachelorette-Party'),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        ),
        body: Stack(
          children: [
            // Hintergrundbild
            Container(
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  opacity: 0.2,
                  image: AssetImage(
                      "assets/images/background/bachelorette_back.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Hauptinhalt als SingleChildScrollView
            SingleChildScrollView(
              child: Column(
                children: [
                  // Card Items ohne weitere ListView
                  ...items,
                  Padding(padding: EdgeInsets.only(top: 15)),
                  FourSecretsDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Begleitet von engsten Freundinnen, startet der besondere Tag "
                          "mit einem JGA, der einen exklusiven Hairstyling- und Make-up-Workshop "
                          "in einer stilvollen Lounge beinhaltet.",
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Was erwartet euch?",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),

                        // Bullet Point Liste
                        BulletPoint(
                            "Glow & Style Workshop: Step-by-Step Anleitung für Make-up und Hairstyling"),
                        BulletPoint(
                            "Exclusive Privat-Lounge in meinem 4secrets-Studio im Glockenbachviertel"),
                        BulletPoint(
                            "Spaß & Beauty-Vibes sowie alle Tools und Produkte"),

                        SizedBox(height: 10),
                        Text(
                          "Nachdem ihr eure perfekten Looks kreiert habt, könnt "
                          "ihr gemeinsam das lebendige Glockenbachviertel erkunden "
                          "und ein vielseitiges Abendprogramm genießen. "
                          "Euch erwarten unvergessliche Augenblicke voller Glamour. ",
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(top: 12.5),
                  ),

                  FourSecretsDivider(padValue: 0),

                  CarouselSliderWidget(
                    images: images,
                    activeIndex: activeIndex,
                    height: 330,
                    viewportFraction: 0.95,
                    enlargeFactor: 0.4,
                  ),

                  // Platz für Footer-Buttons
                  SizedBox(height: 80),
                ],
              ),
            ),

            // Footer Buttons
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 65,
                color: Colors.white54,
                alignment: Alignment.center,
                child: FooterButtons(
                  urlHomepage: urlHomepage,
                  urlMode: urlMode,
                  mailAdress: mailAdress,
                  videoUri: videoUri,
                  videoAsset: videoAsset,
                  videoRatio: videoRatio,
                  urlInstagram: urlInstagram,
                  buttonSize: 45,
                  iconSize: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Widget für Bullet Points
Widget BulletPoint(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("• ", style: TextStyle(fontSize: 16)),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
