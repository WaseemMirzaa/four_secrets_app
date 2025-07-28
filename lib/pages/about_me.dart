import 'package:four_secrets_wedding_app/data/about_me_data.dart';
import 'package:four_secrets_wedding_app/data/about_me_images.dart';
import 'package:four_secrets_wedding_app/model/swipeable_card_widget.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:four_secrets_wedding_app/model/url_email_instagram.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/gestures.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutMe extends StatefulWidget {
  const AboutMe({super.key});

  @override
  State<AboutMe> createState() => _AboutMeState();
}

class _AboutMeState extends State<AboutMe> {
  late List<String> images = AboutMeImages.getImages();
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

  TextStyle? _textStyleBlackBold() {
    return const TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
    );
  }

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
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          title: const Text('Über mich'),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 440,
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
                        height: 150,
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
                              left: 8,
                              right: 8,
                              child: RichText(
                                text: TextSpan(
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: 'Die ',
                                      style: GoogleFonts.openSans(
                                          color: Colors.black),
                                    ),
                                    TextSpan(
                                      text: 'Gründerin',
                                      style: GoogleFonts.openSans(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(
                                      text: ' des ',
                                      style: _textStyleBlack(),
                                    ),
                                    TextSpan(
                                      text: '4secrets Studios',
                                      style: _textStyleBlackBold(),
                                    ),
                                    TextSpan(
                                      text: ' in ',
                                      style: _textStyleBlack(),
                                    ),
                                    TextSpan(
                                      text: 'München',
                                      style: _textStyleBlackBold(),
                                    ),
                                    TextSpan(
                                      text: ' und der dazugehörigen',
                                      style: _textStyleBlack(),
                                    ),
                                    TextSpan(
                                      text: ' App.',
                                      style: _textStyleBlackBold(),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 178,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.only(right: 20),
                        width: 320,
                        height: 255,
                        color: Colors.white,
                        child: RichText(
                          text: TextSpan(
                            children: <TextSpan>[
                              TextSpan(
                                text:
                                    "Mit 19 Jahren Berufserfahrung bin ich eine erfahrene Friseurmeisterin und Make-up Artistin. Im Jahr 2012 eröffnete ich mein erstes Friseur- und Make-up-Studio mit einem klaren Fokus auf Hochzeiten. Ein weiteres Studio folgte 2021 im malerischen Glockenbachviertel in München. Im Verlauf meiner Karriere habe ich mit renommierten Zeitschriften und zahlreichen Fotografen zusammengearbeitet. Mein Studio erhielt in den Jahren 2019 und 2024 Anerkennung",
                                style:
                                    GoogleFonts.openSans(color: Colors.black),
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
                                    " als eines der 15 besten in Deutschland, Österreich und der Schweiz.",
                                style:
                                    GoogleFonts.openSans(color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              FourSecretsDivider(),
              Column(
                children: [
                  SwipeableCardWidget(
                    images: images,
                    height: 450,
                  ),
                ],
              ),
              FourSecretsDivider(),
              Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(
                      left: 20,
                    ),
                    width: 320,
                    color: Colors.white,
                    padding: const EdgeInsets.only(top: 8, right: 8, bottom: 8),
                    child: ExpandableText(
                      "Während ich Brautpaare an ihren besonderen Tagen begleitete, wurde mir die zeitaufwendige Natur der Hochzeitsvorbereitungen bewusst. Diese Erkenntnis inspirierte mich dazu, Brautpaare in diesem Prozess zu unterstützen. Aus dieser Inspiration heraus entstand meine Wedding-Planner-App, die darauf abzielt, einen reibungslosen und harmonischen Ablauf für diesen Tag zu gewährleisten.\n\n" +
                          "Als erfahrene Hochzeits- und Make-up-Künstlerin halte ich mich kontinuierlich über die aktuellen Trends im Hochzeitsbereich auf dem Laufenden. Meine kreative Gestaltung kennt dabei keine Grenzen, und ich lege besonderen Wert darauf, die Einzigartigkeit jedes Brautpaares in meiner Arbeit zum Ausdruck zu bringen.",
                      maxLines: 8,
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
                ],
              ),
              SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    child: Icon(
                      Icons.play_circle,
                      size: 30,
                    ),
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
                        shape: CircleBorder(),
                        foregroundColor: Color.fromARGB(255, 107, 69, 106),
                        elevation: 2.5),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
