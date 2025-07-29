import 'package:four_secrets_wedding_app/data/unterhaltung_card_data.dart';
import 'package:four_secrets_wedding_app/model/card_front_widget.dart';
import 'package:flutter/material.dart';

class UnterhaltungCardItems {
  static List getCardItems() {
    List<Widget> items = [
      CardWidget(
        className: UnterhaltungCardData,
        avatarImage: UnterhaltungCardData.map1['avatar']!,
        vorname: UnterhaltungCardData.map1['vorname']!,
        nachname: UnterhaltungCardData.map1['nachname']!,
        bezeichnung: UnterhaltungCardData.map1['bezeichnung']!,
        backCardTaetigkeit: UnterhaltungCardData.map1['backCardTaetigkeit']!,
        slogan: UnterhaltungCardData.map1['slogan']!,
        homepage: UnterhaltungCardData.map1['homepage']!,
        email: UnterhaltungCardData.map1['email']!,
        instagram: UnterhaltungCardData.map1["instagram"]!,
        phoneNumber: UnterhaltungCardData.map1["phoneNumber"]!,
        videoAsset: UnterhaltungCardData.map1["videoAsset"]!,
        videoRatio: UnterhaltungCardData.map1["videoRatio"]!,
        videoUri: UnterhaltungCardData.map1["videoUri"]!,
      ),
    ];
    return items;
  }
}
