import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:four_secrets_wedding_app/data/about_me_data.dart';
import 'package:four_secrets_wedding_app/data/about_me_images.dart';
import 'package:four_secrets_wedding_app/model/swipeable_card_widget.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:four_secrets_wedding_app/model/url_email_instagram.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/menue.dart';

class AboutMe extends StatefulWidget {
  const AboutMe({super.key});

  @override
  State<AboutMe> createState() => _AboutMeState();
}

class _AboutMeState extends State<AboutMe> {
  late List<String> images = AboutMeImages.getImages();
  int activeIndex = 0;
  String modeUrl = "default";
  
  var videoAsset = AboutMeData.map["videoAsset"] != null
      ? AboutMeData.map["videoAsset"]!
      : "";
  var videoUri =
      AboutMeData.map["videoUri"] != null ? AboutMeData.map["videoUri"]! : "";
  var videoRatio = AboutMeData.map["videoRatio"] != null
      ? AboutMeData.map["videoRatio"]!
      : "";
  var urlHomepage =
      AboutMeData.map["topHair"] != null ? AboutMeData.map["topHair"]! : "";

  final colorizeColors = [
    Colors.black,
    Colors.purple,
    Colors.grey.shade700,
    const Color.fromARGB(255, 229, 229, 229),
  ];

  final colorizeTextStyle = const TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    fontFamily: 'Horizon',
  );

  TextStyle? _textStyleBlack() {
    return const TextStyle(
      color: Colors.black,
    );
  }

  final key = GlobalKey<MenueState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue.getInstance(key),
        appBar: AppBar(
          foregroundColor: const Color.fromARGB(255, 255, 255, 255),
          title: const Text(
            'Über mich',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 860,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      height: 100,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color.fromARGB(255, 107, 69, 106),
                            Color.fromARGB(255, 173, 101, 170),
                            Color.fromARGB(255, 210, 159, 208),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 18,
                      left: 20,
                      child: Image.asset(
                        'assets/images/about_me/about_me_header.jpg',
                        height: 158,
                      ),
                    ),
                    Positioned(
                      top: 50,
                      left: 140,
                      child: Container(
                        height: 130,
                        width: 200,
                        color: Colors.white,
                        child: Stack(
                          children: [
                            Container(
                              height: 50,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.grey.shade100,
                                    Colors.grey.shade200,
                                    Colors.grey.shade300,
                                    Colors.grey.shade400,
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: 12,
                                  left: 8,
                                  bottom: 0,
                                ),
                                child: AnimatedTextKit(
                                  repeatForever: false,
                                  totalRepeatCount: 2,
                                  animatedTexts: [
                                    ColorizeAnimatedText(
                                      'Hi! Ich bin Elena',
                                      textStyle: colorizeTextStyle,
                                      colors: colorizeColors,
                                      speed: const Duration(milliseconds: 500),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                                top: 65,
                                left: 4,
                                right: 2,
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.openSans(
                                      color: Colors.black,
                                      height: 1.5,
                                    ),
                                    children: [
                                      const TextSpan(text: 'Die '),
                                      const TextSpan(
                                        text: 'Gründerin',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const TextSpan(text: ' der '),
                                      const TextSpan(
                                        text: '4secrets-wedding App',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const TextSpan(text: ' und des '),
                                      const TextSpan(
                                        text: '4secrets Studios',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const TextSpan(text: ' in München.'),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 195,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.only(
                            left: 5, right: 20, top: 5, bottom: 5),
                        width: 320,
                        color: Colors.white,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    "Wer steckt hinter der 4secrets-wedding App?\n\n",
                                style: GoogleFonts.openSans(
                                  color: Colors.black,
                                ),
                              ),
                              TextSpan(
                                text:
                                    "Mit über 18 Jahren Berufserfahrung bin ich eine "
                                    "erfahrene Friseurmeisterin und Make-up Artistin. "
                                    "Im Jahr 2012 eröffnete ich mein Friseur- "
                                    "und Make-up-Studio mit einem klaren Fokus auf "
                                    "Hochzeiten. Heute findet ihr mich "
                                    "im malerischen Glockenbachviertel in München. "
                                    "Im Verlauf meiner Karriere habe ich mit renommierten "
                                    "Zeitschriften und zahlreichen Fotografen zusammengearbeitet. "
                                    "Mein 4Secrets Studio erhielt schon mehrfach Anerkennung",
                                style: GoogleFonts.openSans(
                                  color: Colors.black,
                                  height: 1.5, // Erhöht den Zeilenabstand
                                ),
                              ),
                              TextSpan(
                                text: ' von',
                                style: _textStyleBlack(),
                              ),
                              TextSpan(
                                text: ' Top Hair',
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 107, 69, 106),
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    if (urlHomepage.isNotEmpty) {
                                      UrlEmailInstagram.getLaunchHomepage(
                                          url: urlHomepage,
                                          modeString: modeUrl);
                                    }
                                  },
                              ),
                              TextSpan(
                                text:
                                    " als eines der 15 besten Studios in Deutschland, Österreich und der Schweiz.",
                                style:
                                    GoogleFonts.openSans(color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 520,
                      left: 20,
                      right: 20,
                      child: Image.asset(
                        'assets/images/about_me/about_me_main.jpg',
                        height: 350,
                      ),
                    ),
                  ],
                ),
              ),
              
              FourSecretsDivider(),
              
              // Image Gallery Section
              Column(
                children: [
                  SwipeableCardWidget(
                    images: images,
                    height: 450,
                  ),
                ],
              ),
              
              const SizedBox(height: 15),
              
              // Expandable Text Section
              Container(
                width: 320,
                margin: const EdgeInsets.only(left: 20),
                color: Colors.white,
                child: const Padding(
                  padding: EdgeInsets.all(5),
                  child: ExpandableText(
                    "Bereits seit über 15 Jahren begleite ich Paare an einem der wichtigsten Tage ihres Lebens. "
                    "Ich durfte Freudentränen sehen, Nervosität lindern - und dabei immer wieder "
                    "hautnah miterleben, wie viel Organisation, Zeit und Stress hinter einer Hochzeit steckt. "
                    "Eins viel mir dabei besonders auf: Viele Paare verlieren sich in der Planung "
                    "und vergessen dabei, den Moment zu genießen. "
                    "Aus dem Wunsch heraus, Brautpaare nicht nur am Hochzeitstag, sondern schon während "
                    "der gesamten Planung zur Seite zu stehen, entstand 4secrets-wedding App - eine liebevoll gestaltete App, "
                    "die euch Klarheit, Struktur und Ruhe schenkt. "
                    "Jede Braut, jede Freundin, jede Begegnung ist für mich mehr als ein Job - "
                    "es ist Teil einer Herzensgeschichte, die ich mitschreiben darf. ",
                    maxLines: 3,
                    expandText: 'show more',
                    collapseText: 'show less',
                    collapseOnTextTap: true,
                    linkStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 107, 69, 106),
                    ),
                    animation: true,
                    animationDuration: Duration(milliseconds: 600),
                    animationCurve: Curves.easeInOut,
                  ),
                ),
              ),
              
              const SizedBox(height: 15),
              
              // Video Play Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (videoAsset.isNotEmpty || videoUri.isNotEmpty) {
                        Navigator.of(context).pushNamed(
                          RouteManager.videoPlayer2,
                          arguments: {
                            'asset': videoAsset,
                            'uri': videoUri,
                            'ratio': videoRatio,
                          },
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      foregroundColor: const Color.fromARGB(255, 107, 69, 106),
                      elevation: 2.5,
                    ),
                    child: const Icon(
                      Icons.play_circle,
                      size: 30,
                    ),
                  ),
                ],
              ),
              
              const Padding(
                padding: EdgeInsets.only(bottom: 25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}