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
        backCardAdress1: BrautBraeutigamCardData.map1['backCardAdresse1']!,
        backCardAdress2: BrautBraeutigamCardData.map1['backCardAdresse2']!,
        homepage: BrautBraeutigamCardData.map1['homepage']!,
        email: BrautBraeutigamCardData.map1["email"]!,
        phoneNumber: BrautBraeutigamCardData.map1["phoneNumber"]!,
        instagram: BrautBraeutigamCardData.map1["instagram"]!,
        videoAsset: BrautBraeutigamCardData.map1["videoAsset"]!,
        videoRatio: BrautBraeutigamCardData.map1["videoRatio"]!,
        videoUri: BrautBraeutigamCardData.map1["videoUri"]!,
      ),
    ];
    return items;
  }
}
