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
        slogan: FloristCardData.map1['slogan']!,
        homepage: FloristCardData.map1['homepage']!,
        email: FloristCardData.map1["email"]!,
        instagram: FloristCardData.map1["instagram"]!,
        phoneNumber: FloristCardData.map1["phoneNumber"]!,
        videoAsset: FloristCardData.map1["videoAsset"]!,
        videoRatio: FloristCardData.map1["videoRatio"]!,
        videoUri: FloristCardData.map1["videoUri"]!,
      )
    ];
    return items;
  }
}
