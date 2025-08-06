import 'package:four_secrets_wedding_app/data/patiserie_card_data.dart';
import 'package:four_secrets_wedding_app/model/card_front_widget.dart';
import 'package:flutter/material.dart';

class PatiserieCardItems {
  static List getCardItems() {
    List<Widget> items = [
      CardWidget(
        className: PatiserieCardData,
        avatarImage: PatiserieCardData.map1['avatar']!,
        vorname: PatiserieCardData.map1['vorname']!,
        nachname: PatiserieCardData.map1['nachname']!,
        bezeichnung: PatiserieCardData.map1['bezeichnung']!,
        backCardTaetigkeit: PatiserieCardData.map1['backCardTaetigkeit']!,
        slogan: PatiserieCardData.map1['slogan']!,
        homepage: PatiserieCardData.map1['homepage']!,
        email: PatiserieCardData.map1['email']!,
        instagram: PatiserieCardData.map1["instagram"]!,
        phoneNumber: PatiserieCardData.map1["phoneNumber"]!,
        videoAsset: PatiserieCardData.map1["videoAsset"]!,
        videoRatio: PatiserieCardData.map1["videoRatio"]!,
        videoUri: PatiserieCardData.map1["videoUri"]!,
      )
    ];
    return items;
  }
}
