import 'package:four_secrets_wedding_app/data/bachelorette_card_data.dart';
import 'package:four_secrets_wedding_app/model/card_front_widget.dart';
import 'package:flutter/material.dart';

class BacheloretteCardItems {
  static List getCardItems() {
    List<Widget> items = [
      CardWidget(
        className: BacheloretteCardData,
        avatarImage: BacheloretteCardData.map1['avatar']!,
        vorname: BacheloretteCardData.map1['vorname']!,
        nachname: BacheloretteCardData.map1['nachname']!,
        bezeichnung: BacheloretteCardData.map1['bezeichnung']!,
        backCardTaetigkeit: BacheloretteCardData.map1['backCardTaetigkeit']!,
        slogan: BacheloretteCardData.map1['slogan']!,
        homepage: BacheloretteCardData.map1['homepage']!,
        email: BacheloretteCardData.map1["email"]!,
        instagram: BacheloretteCardData.map1["instagram"]!,
        phoneNumber: BacheloretteCardData.map1["phoneNumber"]!,
        videoAsset: BacheloretteCardData.map1["videoAsset"]!,
        videoRatio: BacheloretteCardData.map1["videoRatio"]!,
        videoUri: BacheloretteCardData.map1["videoUri"]!,
      ),
    ];
    return items;
  }
}
