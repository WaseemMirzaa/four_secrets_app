import 'package:four_secrets_wedding_app/data/trauredner_cart_data.dart';
import 'package:four_secrets_wedding_app/model/card_front_widget.dart';
import 'package:flutter/material.dart';

class TraurednerCardItems {
  static List getCardItems() {
    List<Widget> items = [
      CardWidget(
        className: TraurednerCardData,
        avatarImage: TraurednerCardData.map1['avatar']!,
        vorname: TraurednerCardData.map1['vorname']!,
        nachname: TraurednerCardData.map1['nachname']!,
        bezeichnung: TraurednerCardData.map1['bezeichnung']!,
        backCardTaetigkeit: TraurednerCardData.map1['backCardTaetigkeit']!,
        slogan: TraurednerCardData.map1['slogan']!,
        homepage: TraurednerCardData.map1['homepage']!,
        email: TraurednerCardData.map1['email']!,
        instagram: TraurednerCardData.map1["instagram"]!,
        phoneNumber: TraurednerCardData.map1["phoneNumber"]!,
        videoAsset: TraurednerCardData.map1["videoAsset"]!,
        videoRatio: TraurednerCardData.map1["videoRatio"]!,
        videoUri: TraurednerCardData.map1["videoUri"]!,
      ),
    ];
    return items;
  }
}
