import 'package:four_secrets_wedding_app/data/kontakt_data.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/model/url_email_instagram.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class Kontakt extends StatelessWidget {
  Kontakt({super.key});
  var phoneNumber = KontaktData.map["phoneNumber"] != null
      ? KontaktData.map["phoneNumber"]!
      : "";

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue.getInstance(),
        appBar: AppBar(
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          // automaticallyImplyLeading: false,
          title: const Text('Kontakt'),
          backgroundColor: Color.fromARGB(255, 107, 69, 106),
        ),
        body: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              opacity: 0.2,
              image: AssetImage("assets/images/kontakt/kontaktseite.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: SingleChildScrollView(
            physics: ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 45),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Hi, schön von Dir zu hören!",
                    style: TextStyle(
                      fontSize: 24,
                      color: Color.fromARGB(255, 107, 69, 106),
                    ),
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            "HIER FINDEST DU MICH:",
                            style: TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 107, 69, 106),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      Row(
                        children: [
                          Text(
                            "4secrets Studio München",
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            "Inhaberin & Gründerin: Elena Koller",
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            "Baaderstraße 88",
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            "80469 München",
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 1.5),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.5,
                            ),
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      if (phoneNumber.isNotEmpty) {
                                        UrlEmailInstagram.openDialPad(
                                            phoneNumber);
                                      }
                                    },
                                  text: phoneNumber,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                      ),
                      Row(
                        children: [
                          Text(
                            "UNSERE ÖFFNUNGSZEITEN:",
                            style: TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 107, 69, 106),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Dienstag:",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "nach Vereinbarung",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Mittwoch:",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "09:00 - 18:00",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Donnerstag:",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "10:00 - 19:00",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Freitag:",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "09:00 - 18:00",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Samstag:",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "09:00 - 14:00",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 25),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
