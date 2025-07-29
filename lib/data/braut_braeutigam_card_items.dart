import 'package:four_secrets_wedding_app/data/braut_braeutigam_card_data.dart';
import 'package:four_secrets_wedding_app/model/card_front_widget.dart';
import 'package:flutter/material.dart';

class BrautBraeutigamCardItems {
  static List getCardItems() {
    List<Widget> items = [
      CardWidget(
        className: BrautBraeutigamCardData,
        avatarImage: BrautBraeutigamCardData.map1['avatar']!,
        vorname: BrautBraeutigamCardData.map1['vorname']!,
        nachname: BrautBraeutigamCardData.map1['nachname']!,
        bezeichnung: BrautBraeutigamCardData.map1['bezeichnung']!,
        backCardTaetigkeit: BrautBraeutigamCardData.map1['backCardTaetigkeit']!,
        slogan: BrautBraeutigamCardData.map1['slogan']!,
        homepage: BrautBraeutigamCardData.map1['homepage']!,
        email: BrautBraeutigamCardData.map1["email"]!,
        phoneNumber: BrautBraeutigamCardData.map1["phoneNumber"]!,
        instagram: BrautBraeutigamCardData.map1["instagram"]!,
        videoAsset: BrautBraeutigamCardData.map1["videoAsset"]!,
        videoRatio: BrautBraeutigamCardData.map1["videoRatio"]!,
        videoUri: BrautBraeutigamCardData.map1["videoUri"]!,
      ),
      CardWidget(
        className: BrautBraeutigamCardData,
        avatarImage: BrautBraeutigamCardData.map2['avatar']!,
        vorname: BrautBraeutigamCardData.map2['vorname']!,
        nachname: BrautBraeutigamCardData.map2['nachname']!,
        bezeichnung: BrautBraeutigamCardData.map2['bezeichnung']!,
        backCardTaetigkeit: BrautBraeutigamCardData.map2['backCardTaetigkeit']!,
        slogan: BrautBraeutigamCardData.map2['slogan']!,
        homepage: BrautBraeutigamCardData.map2['homepage']!,
        email: BrautBraeutigamCardData.map2["email"]!,
        phoneNumber: BrautBraeutigamCardData.map2["phoneNumber"]!,
        instagram: BrautBraeutigamCardData.map2["instagram"]!,
        videoAsset: BrautBraeutigamCardData.map2["videoAsset"]!,
        videoRatio: BrautBraeutigamCardData.map2["videoRatio"]!,
        videoUri: BrautBraeutigamCardData.map2["videoUri"]!,
      ),
      CardWidget(
        className: BrautBraeutigamCardData,
        avatarImage: BrautBraeutigamCardData.map3['avatar']!,
        vorname: BrautBraeutigamCardData.map3['vorname']!,
        nachname: BrautBraeutigamCardData.map3['nachname']!,
        bezeichnung: BrautBraeutigamCardData.map3['bezeichnung']!,
        backCardTaetigkeit: BrautBraeutigamCardData.map3['backCardTaetigkeit']!,
        slogan: BrautBraeutigamCardData.map3['slogan']!,
        homepage: BrautBraeutigamCardData.map3['homepage']!,
        email: BrautBraeutigamCardData.map3["email"]!,
        phoneNumber: BrautBraeutigamCardData.map3["phoneNumber"]!,
        instagram: BrautBraeutigamCardData.map3["instagram"]!,
        videoAsset: BrautBraeutigamCardData.map3["videoAsset"]!,
        videoRatio: BrautBraeutigamCardData.map3["videoRatio"]!,
        videoUri: BrautBraeutigamCardData.map3["videoUri"]!,
      ),
    ];
    return items;
  }
}
