import 'package:four_secrets_wedding_app/data/florist_card_data.dart';
import 'package:four_secrets_wedding_app/model/card_front_widget.dart';
import 'package:flutter/material.dart';

class FloristCardItems {
  static List getCardItems() {
    List<Widget> items = [
      CardWidget(
        className: FloristCardData,
        avatarImage: FloristCardData.map1['avatar']!,
        vorname: FloristCardData.map1['vorname']!,
        nachname: FloristCardData.map1['nachname']!,
        bezeichnung: FloristCardData.map1['bezeichnung']!,
        backCardTaetigkeit: FloristCardData.map1['backCardTaetigkeit']!,
        backCardAdress1: FloristCardData.map1['backCardAdresse1']!,
        backCardAdress2: FloristCardData.map1['backCardAdresse2']!,
        homepage: FloristCardData.map1['homepage']!,
        email: FloristCardData.map1["email"]!,
        instagram: FloristCardData.map1["instagram"]!,
        phoneNumber: FloristCardData.map1["phoneNumber"]!,
        videoAsset: FloristCardData.map1["videoAsset"]!,
        videoRatio: FloristCardData.map1["videoRatio"]!,
        videoUri: FloristCardData.map1["videoUri"]!,
      ),
      CardWidget(
        className: FloristCardData,
        avatarImage: FloristCardData.map2['avatar']!,
        vorname: FloristCardData.map2['vorname']!,
        nachname: FloristCardData.map2['nachname']!,
        bezeichnung: FloristCardData.map2['bezeichnung']!,
        backCardTaetigkeit: FloristCardData.map2['backCardTaetigkeit']!,
        backCardAdress1: FloristCardData.map2['backCardAdresse1']!,
        backCardAdress2: FloristCardData.map2['backCardAdresse2']!,
        homepage: FloristCardData.map2['homepage']!,
        email: FloristCardData.map2["email"]!,
        instagram: FloristCardData.map2["instagram"]!,
        phoneNumber: FloristCardData.map2["phoneNumber"]!,
        videoAsset: FloristCardData.map1["videoAsset"]!,
        videoRatio: FloristCardData.map1["videoRatio"]!,
        videoUri: FloristCardData.map1["videoUri"]!,
      ),
    ];
    return items;
  }
}
