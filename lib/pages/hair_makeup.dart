import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/data/hair_makeup_data.dart';
import 'package:four_secrets_wedding_app/data/hair_makeup_images.dart';
import 'package:four_secrets_wedding_app/data/hair_makeup_card_items.dart';
import 'package:four_secrets_wedding_app/model/swipeable_card_widget.dart';
import 'package:four_secrets_wedding_app/model/footer_buttons.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/menue.dart';

// ignore: must_be_immutable
class HairMakeUp extends StatelessWidget {
  HairMakeUp({super.key});
  
  final List items = HairMakeUpCardItems.getCardItems();
  late List<String> images = HairMakeUpImages.getImages();
  final key = GlobalKey<MenueState>();

  int activeIndex = 0;
  String urlMode = "default";

  var urlHomepage = HairMakeUpData.map["homepage"] != null
      ? HairMakeUpData.map["homepage"]!
      : "";

  var urlInstagram = HairMakeUpData.map["instagram"] != null
      ? HairMakeUpData.map["instagram"]!
      : "";

  var mailAdress =
      HairMakeUpData.map["email"] != null ? HairMakeUpData.map["email"]! : "";

  var videoAsset = HairMakeUpData.map["videoAsset"] != null
      ? HairMakeUpData.map["videoAsset"]!
      : "";

  var videoUri = HairMakeUpData.map["videoUri"] != null
      ? HairMakeUpData.map["videoUri"]!
      : "";

  var videoRatio = HairMakeUpData.map["videoRatio"] != null
      ? HairMakeUpData.map["videoRatio"]!
      : "";

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue.getInstance(key),
        appBar: AppBar(
          foregroundColor: const Color.fromARGB(255, 255, 255, 255),
          title: const Text(
            'Hair & Make-Up',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
          actions: [
            // Video icon button in top right
            if (videoAsset.isNotEmpty || videoUri.isNotEmpty)
              IconButton(
                icon: const Icon(
                  Icons.play_circle,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    RouteManager.videoPlayer2,
                    arguments: {
                      'asset': videoAsset,
                      'uri': videoUri,
                      'ratio': videoRatio,
                    },
                  );
                },
                tooltip: 'Video abspielen',
              ),
          ],
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
                      "assets/images/background/hairstyling_makeup_back.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Hauptinhalt als SingleChildScrollView
            SingleChildScrollView(
              child: Column(
                children: [
                  // Image Gallery Section (oben)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: SwipeableCardWidget(
                      images: images,
                      height: 450,
                    ),
                  ),

                  // Card Items (falls vorhanden)
                  ...items,
                  
                  const Padding(padding: EdgeInsets.only(top: 15)),
                  FourSecretsDivider(),
                  
                  // Text Content Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "An deinem Hochzeitstag sollst du dich "
                          "nicht nur besonders fühlen - sondern wie die beste Version "
                          "deiner selbst. "
                          "Ich lege großen Wert auf Natürlichkeit, Authentizität und "
                          "Individualität. Bei mir stehst du im Mittelpunkt - mit "
                          "deinem Typ, deinem persönlichen Stil und deinen eigenen Wünschen. "
                          "Ob du dir ein elegantes Make-up, eine romantische "
                          "Hochsteckfrisur oder einen modernen Boho-Look wünschst - "
                          "ich nehme mir Zeit dich kennenzulernen und dein "
                          "Styling ganz individuell auf dich abzustimmen.",
                        ),
                        
                        const SizedBox(height: 16),
                        
                        const Text(
                          "Für das Probestyling empfange ich dich in meinem Studio, "
                          "einer Privat-Lounge nur für dich, im Glockenbachviertel in München. "
                          "Für deinen Hochzeitstag entscheidest du selbst, ob dein Styling "
                          "bei mir im Studio oder direkt bei dir vor Ort stattfinden soll.",
                        ),
                        
                        const SizedBox(height: 16),
                        
                        const Text(
                          "Mit der Option, den Vor-Ort-Service zu wählen, erlebt "
                          "nicht nur ihr als Brautpaar entspannte Momente, "
                          "sondern auch eure Gäste und Trauzeugen dürfen sich auf "
                          "ein beeindruckendes Highlight freuen.",
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.only(top: 12.5),
                  ),

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