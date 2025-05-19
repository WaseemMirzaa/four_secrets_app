import 'package:four_secrets_wedding_app/model/url_email_instagram.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class CardAdress {
  // Widget if Member has only one adress
  static Widget oneAdress(
      String backCardTaetigkeit, String backCardAdress1, var phoneNumber) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(
            top: 34.2,
          ),
          child: Text(
            backCardTaetigkeit,
            overflow: TextOverflow.clip,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 20),
          child: Text(
            backCardAdress1,
            overflow: TextOverflow.clip,
          ),
        ),
        Container(
          child: Text.rich(
            TextSpan(
              children: [
                WidgetSpan(
                  child: Container(
                    padding: EdgeInsets.only(top: 2, right: 3),
                    child: hasPhoneNumber(phoneNumber),
                  ),
                ),
                TextSpan(
                  text: phoneNumber,
                  style: TextStyle(fontSize: 14),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      if (phoneNumber.isNotEmpty) {
                        UrlEmailInstagram.openDialPad(phoneNumber);
                      }
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget if Member has two adresses
  static Widget twoAdress(String backCardTaetigkeit, String backCardAdress1,
      String backCardAdress2, var phoneNumber) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          margin: EdgeInsets.only(top: 34.2),
          child: Text(
            backCardTaetigkeit,
            overflow: TextOverflow.clip,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
              ),
              Text(
                backCardAdress1,
                overflow: TextOverflow.clip,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 13),
              ),
              Text(
                backCardAdress2,
                overflow: TextOverflow.clip,
              ),
            ],
          ),
        ),
        Container(
          width: 300,
          child: Text.rich(
            TextSpan(
              children: [
                WidgetSpan(
                  child: Container(
                    padding: EdgeInsets.only(top: 2, right: 3),
                    child: hasPhoneNumber(phoneNumber),
                  ),
                ),
                TextSpan(
                  text: phoneNumber,
                  style: TextStyle(fontSize: 14),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      if (phoneNumber.isNotEmpty) {
                        UrlEmailInstagram.openDialPad(phoneNumber);
                      }
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget hasPhoneNumber(var phoneNumber) {
    if (phoneNumber.isNotEmpty) {
      return Icon(
        Icons.phone,
        size: 18,
      );
    } else
      return Container(
        child: Text(""),
      );
  }
}
