import 'package:four_secrets_wedding_app/data/papeterie_card_data.dart';
import 'package:four_secrets_wedding_app/model/card_front_widget.dart';
import 'package:flutter/material.dart';

class PapeterieCardItems {
  static List getCardItems() {
    List<Widget> items = [
      CardWidget(
        className: PapeterieCardData,
        avatarImage: PapeterieCardData.map1['avatar']!,
        vorname: PapeterieCardData.map1['vorname']!,
        nachname: PapeterieCardData.map1['nachname']!,
        bezeichnung: PapeterieCardData.map1['bezeichnung']!,
        backCardTaetigkeit: PapeterieCardData.map1['backCardTaetigkeit']!,
        slogan: PapeterieCardData.map1['slogan']!,
        homepage: PapeterieCardData.map1['homepage']!,
        email: PapeterieCardData.map1['email']!,
        instagram: PapeterieCardData.map1["instagram"]!,
        phoneNumber: PapeterieCardData.map1["phoneNumber"]!,
        videoAsset: PapeterieCardData.map1["videoAsset"]!,
        videoRatio: PapeterieCardData.map1["videoRatio"]!,
        videoUri: PapeterieCardData.map1["videoUri"]!,
      ),
      CardWidget(
        className: PapeterieCardData,
        avatarImage: PapeterieCardData.map2['avatar']!,
        vorname: PapeterieCardData.map2['vorname']!,
        nachname: PapeterieCardData.map2['nachname']!,
        bezeichnung: PapeterieCardData.map2['bezeichnung']!,
        backCardTaetigkeit: PapeterieCardData.map2['backCardTaetigkeit']!,
        slogan: PapeterieCardData.map2['slogan']!,
        homepage: PapeterieCardData.map2['homepage']!,
        email: PapeterieCardData.map2['email']!,
        instagram: PapeterieCardData.map2["instagram"]!,
        phoneNumber: PapeterieCardData.map2["phoneNumber"]!,
        videoAsset: PapeterieCardData.map2["videoAsset"]!,
        videoRatio: PapeterieCardData.map2["videoRatio"]!,
        videoUri: PapeterieCardData.map2["videoUri"]!,
      ),
    ];
    return items;
  }
}
