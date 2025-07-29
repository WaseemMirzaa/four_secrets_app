import 'package:four_secrets_wedding_app/data/hair_makeup_card_data.dart';
import 'package:four_secrets_wedding_app/model/card_front_widget.dart';
import 'package:flutter/material.dart';

class HairMakeUpCardItems {
  static List getCardItems() {
    List<Widget> items = [
      CardWidget(
        className: HairMakeUpCardData,
        avatarImage: HairMakeUpCardData.map1['avatar']!,
        vorname: HairMakeUpCardData.map1['vorname']!,
        nachname: HairMakeUpCardData.map1['nachname']!,
        bezeichnung: HairMakeUpCardData.map1['bezeichnung']!,
        backCardTaetigkeit: HairMakeUpCardData.map1['backCardTaetigkeit']!,
        slogan: HairMakeUpCardData.map1['slogan']!,
        homepage: HairMakeUpCardData.map1['homepage']!,
        email: HairMakeUpCardData.map1["email"]!,
        instagram: HairMakeUpCardData.map1["instagram"]!,
        phoneNumber: HairMakeUpCardData.map1["phoneNumber"]!,
        videoAsset: HairMakeUpCardData.map1["videoAsset"]!,
        videoRatio: HairMakeUpCardData.map1["videoRatio"]!,
        videoUri: HairMakeUpCardData.map1["videoUri"]!,
      ),
    ];
    return items;
  }
}
