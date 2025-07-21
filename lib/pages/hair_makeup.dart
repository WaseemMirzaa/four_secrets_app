import 'package:four_secrets_wedding_app/data/hair_makeup_data.dart';
import 'package:four_secrets_wedding_app/data/hair_makeup_images.dart';
import 'package:four_secrets_wedding_app/model/swipeable_card_widget.dart';
import 'package:four_secrets_wedding_app/model/footer_buttons.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/menue.dart';

// ignore: must_be_immutable
class HairMakeUp extends StatelessWidget {
  HairMakeUp({super.key});

  String urlMode = "default";
  late List<String> images = HairMakeUpImages.getImages();

  final key = GlobalKey<MenueState>();

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
        drawer: Menue.getInstance(key!),
        appBar: AppBar(
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          // automaticallyImplyLeading: false,
          title: const Text('Hair & Make-Up'),
          backgroundColor: Color.fromARGB(255, 107, 69, 106),
          actions: [
            // Video icon button in top right
            if (videoAsset.isNotEmpty || videoUri.isNotEmpty)
              IconButton(
                icon: const Icon(
                  Icons.play_circle,
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
        body: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              opacity: 0.25,
              image: AssetImage(
                  "assets/images/background/hairstyling_makeup_back.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  child: SingleChildScrollView(
                    physics: ClampingScrollPhysics(),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: SwipeableCardWidget(
                            images: images,
                            height: 450,
                          ),
                        ),
                        FourSecretsDivider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          child: Text(
                              "In meinen Hochzeitspaketen steht die Betonung "
                              "der individuellen Schönheit jeder Braut im Mittelpunkt. "
                              "Durch maßgeschneiderte Hairstyles und Make-up-Kreationen "
                              "strebe ich danach, dass sich jede Braut am Hochzeitstag "
                              "selbstbewusst und wunderschön fühlt. Die Vielfalt meiner "
                              "Angebote ermöglicht es, den Fokus auf die persönlichen "
                              "Vorlieben und Stile zu legen. Von romantischen Locken "
                              "bis zu zeitlosen Make-up-Looks - gemeinsam gestalten wir "
                              "einen Look, der deine Einzigartigkeit unterstreicht "
                              "und dein Hochzeitstag zu etwas ganz Besonderem macht.\n\n"
                              "Mit der Option, den Vor-Ort-Service zu wählen, erleben "
                              "nicht nur das Brautpaar entspannte Momente, "
                              "sondern auch Gäste und Trauzeugen dürfen sich auf "
                              "ein beeindruckendes Highlight freuen."),
                        ),
                        FourSecretsDivider(),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                height: 55,
                alignment: Alignment.center,
                margin: EdgeInsets.only(bottom: 10),
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
            ],
          ),
        ),
      ),
    );
  }
}
