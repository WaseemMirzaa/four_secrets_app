import 'package:four_secrets_wedding_app/data/bachelorette_data.dart';
import 'package:four_secrets_wedding_app/data/bachelorette_images.dart';
import 'package:four_secrets_wedding_app/model/swipeable_card_widget.dart';
import 'package:four_secrets_wedding_app/model/footer_buttons.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';

// ignore: must_be_immutable
class BacheloretteParty extends StatelessWidget {
  BacheloretteParty({super.key});

  late List<String> images = BacheloretteImages.getImages();

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

  String urlMode = "default";

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          foregroundColor: const Color.fromARGB(255, 255, 255, 255),
          // automaticallyImplyLeading: false,
          title: const Text(
            'Bachelorette-Party',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
          actions: [
            // White video icon button in top right
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
        body: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              opacity: 0.2,
              image:
                  AssetImage("assets/images/background/bachelorette_back.jpg"),
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
                        SpacerWidget(height: 10),
                        SwipeableCardWidget(
                          images: images,
                          height: 330,
                        ),
                        FourSecretsDivider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          child: Text(
                              "Begleitet von engsten Freundinnen, startet der besondere Tag "
                              "mit einem JGA, der einen exklusiven Hairstyling- und Make-up-Workshop "
                              "in einer stilvollen Lounge beinhaltet. Nachdem ihr eure perfekten "
                              "Looks kreiert habt, erkundet gemeinsam das lebendige Glockenbachviertel "
                              "und genießt ein vielseitiges Abendprogramm. "
                              "Freut euch auf eine blendende Zeit voller Glamour "
                              "und unvergesslicher Augenblicke!"),
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
