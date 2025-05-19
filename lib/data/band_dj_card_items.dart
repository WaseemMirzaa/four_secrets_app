import 'package:four_secrets_wedding_app/data/band_dj_card_data.dart';
import 'package:flutter/material.dart';

import '../model/card_front_widget.dart';

class BandDjCardItems {
  static List getCardItems() {
    List<Widget> items = [
      CardWidget(
        className: BandDjCardData,
        avatarImage: BandDjCardData.map1['avatar']!,
        vorname: BandDjCardData.map1['vorname']!,
        nachname: BandDjCardData.map1['nachname']!,
        bezeichnung: BandDjCardData.map1['bezeichnung']!,
        backCardTaetigkeit: BandDjCardData.map1['backCardTaetigkeit']!,
        backCardAdress1: BandDjCardData.map1['backCardAdresse1']!,
        backCardAdress2: BandDjCardData.map1['backCardAdresse2']!,
        homepage: BandDjCardData.map1['homepage']!,
        email: BandDjCardData.map1["email"]!,
        instagram: BandDjCardData.map1["instagram"]!,
        phoneNumber: BandDjCardData.map1["phoneNumber"]!,
        videoAsset: BandDjCardData.map1["videoAsset"]!,
        videoRatio: BandDjCardData.map1["videoRatio"]!,
        videoUri: BandDjCardData.map1["videoUri"]!,
      ),
    ];
    return items;
  }
}
