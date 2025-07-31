import 'package:four_secrets_wedding_app/model/car_keil_form.dart';
import 'package:four_secrets_wedding_app/model/footer_buttons.dart';
import 'package:four_secrets_wedding_app/model/make_adress_card.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class CardBackWidget extends StatelessWidget {
  Object className;

  final String? backCardAdress2;
  final String? backCardAdress1;
  final backCardTaetigkeit;
  final homepage;
  var modeString;
  String urlMode = "default";
  final String email;
  final String instagram;
  final String videoAsset;
  var videoRatio;
  final String videoUri;
  var phoneNumber;
  var slogan;

  CardBackWidget(
      {super.key,
      required this.className,
      required this.backCardTaetigkeit,
      required this.homepage,
      required this.modeString,
      required this.email,
      required this.phoneNumber,
      required this.slogan,
      required this.instagram,
      required this.videoAsset,
      required this.videoRatio,
      required this.videoUri,
      this.backCardAdress2,
      this.backCardAdress1});

  // Params for checking, if there are one adress or two
  int amountOfAdress = 0;

  // Check Amount of adresses
  int chooseAmountOfAdress() {
    if (backCardAdress1 != null &&
        backCardAdress1!.isNotEmpty &&
        (backCardAdress2 == null || backCardAdress2!.isEmpty)) {
      return 1;
    } else if (backCardAdress1 != null &&
        backCardAdress1!.isNotEmpty &&
        backCardAdress2 != null &&
        backCardAdress2!.isNotEmpty) {
      return 2;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 10,
      margin: EdgeInsets.only(left: 20, right: 20, top: 25),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade300,
              Colors.grey.shade200,
              Colors.grey.shade50
            ],
          ),
        ),
        height: 245,
        child: Stack(
          children: [
            Center(
              child: chooseAmountOfAdress() == 1
                  ? CardAdress.oneAdress(
                      backCardTaetigkeit, backCardAdress1!, phoneNumber)
                  : chooseAmountOfAdress() == 2
                      ? CardAdress.twoAdress(backCardTaetigkeit,
                          backCardAdress1!, backCardAdress2!, phoneNumber)
                      : Text(''),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: EdgeInsets.only(bottom: 3),
                height: 52.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: FooterButtons(
                    urlHomepage: homepage,
                    urlMode: urlMode,
                    mailAdress: email,
                    videoUri: videoUri,
                    videoAsset: videoAsset,
                    videoRatio: videoRatio,
                    urlInstagram: instagram,
                    buttonSize: 40,
                    iconSize: 26,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 20,
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
              ),
            ),
            Container(
              child: KeilForm(),
            ),
            Container(
              margin: EdgeInsets.only(top: 35, left: 6, right: 10),
              height: 20,
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 107, 69, 106),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.shade500,
                      blurRadius: 1.5,
                      spreadRadius: 0.2,
                      offset: Offset(1.5, 1.5),
                      blurStyle: BlurStyle.normal)
                ],
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 12.0), // Hier kannst du den Wert anpassen
                child: Text(
                  "\"" + slogan + "\"",
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  softWrap: true,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
