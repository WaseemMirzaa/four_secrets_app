import 'dart:async';

import 'package:four_secrets_wedding_app/data/showroom_event_data.dart';
import 'package:four_secrets_wedding_app/data/showroom_event_images.dart';
import 'package:four_secrets_wedding_app/model/swipeable_card_widget.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/menue.dart';

// ignore: must_be_immutable
class ShowroomEvent extends StatelessWidget {
  ShowroomEvent({super.key});

  late List<String> images = ShowroomEventImages.getImages();
  int activeIndex = 0;
  var videoAsset = ShowroomEventData.map["videoAsset"] != null
      ? ShowroomEventData.map["videoAsset"]!
      : "";

  var videoUri = ShowroomEventData.map["videoUri"] != null
      ? ShowroomEventData.map["videoUri"]!
      : "";

  var videoRatio = ShowroomEventData.map["videoRatio"] != null
      ? ShowroomEventData.map["videoRatio"]!
      : "";

  final key = GlobalKey<MenueState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue(),
        appBar: AppBar(
          // automaticallyImplyLeading: false,
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          title: const Text('Showroom-Event'),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        ),
        body: Stack(
          children: [
            Container(
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  opacity: 0.2,
                  image: AssetImage(
                      "assets/images/background/showroom_event_back.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
              child: ListView(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    child: Image.asset(
                      'assets/images/showroom_event/showroom_event_1.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  FourSecretsDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ExpandableText(
                        "Das exklusive Showroom Event schafft eine einzigartige "
                        "Umgebung für kleine Gruppen von 10-15 Teilnehmern, "
                        "um die besten Hochzeitsdienstleister Münchens hautnah "
                        "zu erleben. Renommierte Floristen, Fotografen, "
                        "Hairstylisten oder Entertainer präsentieren sich an "
                        "ausgewählten Tagen. Hier kann man sich von kreativen "
                        "Ideen inspirieren lassen, wie durch atemberaubende "
                        "Blumenarrangements oder innovative Hochzeitsdesigner. "
                        "Dadurch gewinnst du  einen ersten Eindruck für die eigene "
                        "Traumhochzeit. Bei jedem Event sorgt der regelmäßige "
                        "Wechsel der Aussteller dafür, dass man ständig positive "
                        "Überraschungen erlebt. Man kann zum Beispiel die "
                        "Köstlichkeiten talentierter Konditoren probieren oder die "
                        "Schönheit der Brautkleider bewundern. Diese einzigartige "
                        "Gelegenheit ermöglicht es, die Vielfalt der Anbieter in "
                        "der App zu entdecken und vereinfacht die präzise Auswahl "
                        "für deine eigene Hochzeit.",
                        maxLines: 8,
                        expandText: 'show more',
                        collapseText: 'show less',
                        linkStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 107, 69, 106),
                        ),
                        collapseOnTextTap: true,
                        animation: true,
                        animationDuration: Duration(milliseconds: 600),
                        animationCurve: Curves.easeInOut,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 12.5),
                  ),
                  FourSecretsDivider(
                      // padValue: 0,
                      ),
                  SwipeableCardWidget(
                    images: images,
                    height: 480,
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
          ],
        ),
      ),
    );
  }
}
