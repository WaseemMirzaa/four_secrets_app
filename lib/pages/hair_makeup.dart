import 'package:DreamWedding/data/hair_makeup_data.dart';
import 'package:DreamWedding/data/hair_makeup_images.dart';
import 'package:DreamWedding/model/carousel_slider_widget.dart';
import 'package:DreamWedding/model/footer_buttons.dart';
import 'package:DreamWedding/model/four_secrets_divider.dart';
import 'package:flutter/material.dart';
import 'package:DreamWedding/menue.dart';
import 'package:DreamWedding/data/hair_makeup_card_items.dart';

// ignore: must_be_immutable
class HairMakeUp extends StatelessWidget {
  HairMakeUp({super.key});
  final List items = HairMakeUpCardItems.getCardItems();

  int activeIndex = 0;
  String urlMode = "default";
  late List<String> images = HairMakeUpImages.getImages();

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
        drawer: const Menue(),
        appBar: AppBar(
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          title: const Text('Hair & Make-Up'),
          backgroundColor: Color.fromARGB(255, 107, 69, 106),
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
                      "assets/images/background/hairstyling_makeup_back.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Hauptinhalt als SingleChildScrollView
            SingleChildScrollView(
              child: Column(
                children: [
                  // Card Items (falls Sie diese später verwenden möchten)
                  ...items,
                  Padding(padding: EdgeInsets.only(top: 15)),
                  FourSecretsDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text("An deinem Hochzeitstag sollst du dich "
                        "nicht nur besonders fühlen - sondern wie die beste Version. "
                        "deiner selbst. "
                        "Ich lege großen Wert auf Natürlichkeit, Authentizität und "
                        "Individualität. Bei mir stehst du im Mittelpunkt - mit "
                        "deinem Typ, deinem persönlichen Stil und deinen eigenen Wünschen. "
                        "Ob du dir ein elegantes Make-up, eine romantische "
                        "Hochsteckfrisur oder einen modernen Boho-Look wünschst - "
                        "ich nehme mir Zeit dich kennenzulernen und  dein "
                        "Styling ganz individuell auf dich abzustimmen."
                        "\n\n"
                        "Für das Probestyling empfange ich dich in meinem meinem Studio, "
                        "einer Privat-Lounge nur für dich, im Glockenbachviertel in München. "
                        "Für deinen Hochzeitstag entscheidest du selbst, ob dein Styling "
                        "bei mir im Studio oder direkt bei dir vor Ort stattfinden soll. "
                        "\n\n"
                        "Mit der Option, den Vor-Ort-Service zu wählen, erlebt "
                        "nicht nur ihr als Brautpaar entspannte Momente, "
                        "sondern auch eure Gäste und Trauzeugen dürfen sich auf "
                        "ein beeindruckendes Highlight freuen."),
                  ),

                  Padding(
                    padding: EdgeInsets.only(top: 12.5),
                  ),

                  FourSecretsDivider(padValue: 0),

                  CarouselSliderWidget(
                      images: images,
                      activeIndex: activeIndex,
                      height: 450,
                      viewportFraction: 0.7,
                      enlargeFactor: 0.4),

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
