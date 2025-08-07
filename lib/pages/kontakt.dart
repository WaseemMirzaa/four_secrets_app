import 'package:four_secrets_wedding_app/data/kontakt_data.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/model/url_email_instagram.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class Kontakt extends StatelessWidget {
  UrlEmailInstagram urlEmailInstagram = UrlEmailInstagram();

  Kontakt({super.key});

  String instagram = KontaktData.map["instagram"] ?? "";
  String email = KontaktData.map["email"] ?? "";
  String homepage = KontaktData.map["homepage"] ?? "";
  final Key key = GlobalKey<MenueState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue.getInstance(key),
        appBar: AppBar(
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          title: const Text('Kontakt'),
          backgroundColor: Color.fromARGB(255, 107, 69, 106),
        ),
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/kontakt/kontaktseite.png"),
              fit: BoxFit.cover, // Füllt den gesamten Hintergrund
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20.0), // Abstand vom Rand
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Links ausrichten
                children: [
                  // INSTAGRAM
                  Row(
                    children: [
                      Icon(
                        Icons.camera_alt,
                        color: Color.fromARGB(255, 107, 69, 106),
                        size: 24,
                      ),
                      const SizedBox(width: 10), // Einheitlicher Abstand
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  if (instagram.isNotEmpty) {
                                    UrlEmailInstagram.getlaunchInstagram(
                                        url: instagram,
                                        modeString: "appBrowser");
                                  }
                                },
                              text: "@4secrets_wedding_planner",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                      height: 15), // Einheitlicher Abstand zwischen den Zeilen

                  // EMAIL
                  Row(
                    children: [
                      Icon(
                        Icons.email,
                        color: Color.fromARGB(255, 107, 69, 106),
                        size: 24,
                      ),
                      const SizedBox(width: 10), // Einheitlicher Abstand
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  if (email.isNotEmpty) {
                                    UrlEmailInstagram.sendEmail(
                                        toEmail: email,
                                        subject: "Kontaktanfrage",
                                        body: "Hier ihre Nachricht...");
                                  }
                                },
                              text: "4secrets-wedding@gmx.de",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                      height: 15), // Einheitlicher Abstand zwischen den Zeilen

                  // WEBSITE
                  Row(
                    children: [
                      Icon(
                        Icons.public,
                        color: Color.fromARGB(255, 107, 69, 106),
                        size: 24,
                      ),
                      const SizedBox(width: 10), // Einheitlicher Abstand
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  if (homepage.isNotEmpty) {
                                    UrlEmailInstagram.getLaunchHomepage(
                                        url: homepage,
                                        modeString: "appBrowser");
                                  }
                                },
                              text: "www.4secrets-wedding-planner.de",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
