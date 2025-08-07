import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/data/bachelorette_data.dart';
import 'package:four_secrets_wedding_app/data/bachelorette_images.dart';
import 'package:four_secrets_wedding_app/data/bachelorette_card_items.dart';
import 'package:four_secrets_wedding_app/model/swipeable_card_widget.dart';
import 'package:four_secrets_wedding_app/model/footer_buttons.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import 'package:four_secrets_wedding_app/menue.dart';

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
        drawer: Menue.getInstance(GlobalKey()),
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
              decoration: const BoxDecoration(
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
                  const Padding(padding: EdgeInsets.only(top: 15)),
                  FourSecretsDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SpacerWidget(height: 10),
                        const Text(
                          "Begleitet von engsten Freundinnen, startet der besondere Tag "
                          "mit einem JGA, der einen exklusiven Hairstyling- und Make-up-Workshop "
                          "in einer stilvollen Lounge beinhaltet.",
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Was erwartet euch?",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),

                        // Bullet Point Liste
                        BulletPoint(
                            "Glow & Style Workshop: Step-by-Step Anleitung für Make-up und Hairstyling"),
                        BulletPoint(
                            "Exclusive Privat-Lounge in meinem 4secrets-Studio im Glockenbachviertel"),
                        BulletPoint(
                            "Spaß & Beauty-Vibes sowie alle Tools und Produkte"),

                        const SizedBox(height: 10),
                        const Text(
                          "Nachdem ihr eure perfekten Looks kreiert habt, könnt "
                          "ihr gemeinsam das lebendige Glockenbachviertel erkunden "
                          "und ein vielseitiges Abendprogramm genießen. "
                          "Euch erwarten unvergessliche Augenblicke voller Glamour. ",
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.only(top: 12.5),
                  ),

                  FourSecretsDivider(),

                  // Image Carousel Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        const SpacerWidget(height: 10),
                        SwipeableCardWidget(
                          images: images,
                          height: 330,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 25),

                  // Platz für Footer-Buttons
                  const SizedBox(height: 80),
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
        const Text("• ", style: TextStyle(fontSize: 16)),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
