import 'package:four_secrets_wedding_app/data/gesang_card_data.dart';
import 'package:four_secrets_wedding_app/model/card_front_widget.dart';
import 'package:flutter/material.dart';

class GesangCardItems {
  static List getCardItems() {
    List<Widget> items = [
      CardWidget(
        className: GesangCardData,
        avatarImage: GesangCardData.map1['avatar']!,
        vorname: GesangCardData.map1['vorname']!,
        nachname: GesangCardData.map1['nachname']!,
        bezeichnung: GesangCardData.map1['bezeichnung']!,
        backCardTaetigkeit: GesangCardData.map1['backCardTaetigkeit']!,
        slogan: GesangCardData.map1['slogan']!,
        homepage: GesangCardData.map1['homepage']!,
        email: GesangCardData.map1['email']!,
        instagram: GesangCardData.map1["instagram"]!,
        phoneNumber: GesangCardData.map1["phoneNumber"]!,
        videoAsset: GesangCardData.map1["videoAsset"]!,
        videoRatio: GesangCardData.map1["videoRatio"]!,
        videoUri: GesangCardData.map1["videoUri"]!,
      ),
      CardWidget(
        className: GesangCardData,
        avatarImage: GesangCardData.map2['avatar']!,
        vorname: GesangCardData.map2['vorname']!,
        nachname: GesangCardData.map2['nachname']!,
        bezeichnung: GesangCardData.map2['bezeichnung']!,
        backCardTaetigkeit: GesangCardData.map2['backCardTaetigkeit']!,
        slogan: GesangCardData.map2['slogan']!,
        homepage: GesangCardData.map2['homepage']!,
        email: GesangCardData.map2['email']!,
        instagram: GesangCardData.map2["instagram"]!,
        phoneNumber: GesangCardData.map2["phoneNumber"]!,
        videoAsset: GesangCardData.map2["videoAsset"]!,
        videoRatio: GesangCardData.map2["videoRatio"]!,
        videoUri: GesangCardData.map2["videoUri"]!,
      ),
    ];
    return items;
  }
}
