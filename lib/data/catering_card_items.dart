import 'package:four_secrets_wedding_app/data/catering_card_data.dart';
import 'package:four_secrets_wedding_app/model/card_front_widget.dart';
import 'package:flutter/material.dart';

class CateringCardItems {
  static List getCardItems() {
    List<Widget> items = [
      CardWidget(
        className: CateringCardData,
        avatarImage: CateringCardData.map1['avatar']!,
        vorname: CateringCardData.map1['vorname']!,
        nachname: CateringCardData.map1['nachname']!,
        bezeichnung: CateringCardData.map1['bezeichnung']!,
        backCardTaetigkeit: CateringCardData.map1['backCardTaetigkeit']!,
        slogan: CateringCardData.map1['slogan']!,
        homepage: CateringCardData.map1['homepage']!,
        email: CateringCardData.map1["email"]!,
        instagram: CateringCardData.map1["instagram"]!,
        phoneNumber: CateringCardData.map1["phoneNumber"]!,
        videoAsset: CateringCardData.map1["videoAsset"]!,
        videoRatio: CateringCardData.map1["videoRatio"]!,
        videoUri: CateringCardData.map1["videoUri"]!,
      )
    ];
    return items;
  }
}
