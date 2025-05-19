import 'package:four_secrets_wedding_app/data/location_card_data.dart';
import 'package:four_secrets_wedding_app/model/card_front_widget.dart';
import 'package:flutter/material.dart';

class LocationCardItems {
  static List getCardItems() {
    List<Widget> items = [
      CardWidget(
        className: LocationCardData,
        avatarImage: LocationCardData.map1['avatar']!,
        vorname: LocationCardData.map1['vorname']!,
        nachname: LocationCardData.map1['nachname']!,
        bezeichnung: LocationCardData.map1['bezeichnung']!,
        backCardTaetigkeit: LocationCardData.map1['backCardTaetigkeit']!,
        backCardAdress1: LocationCardData.map1['backCardAdresse1']!,
        backCardAdress2: LocationCardData.map1['backCardAdresse2']!,
        homepage: LocationCardData.map1['homepage']!,
        email: LocationCardData.map1['email']!,
        instagram: LocationCardData.map1["instagram"]!,
        phoneNumber: LocationCardData.map1["phoneNumber"]!,
        videoAsset: LocationCardData.map1["videoAsset"]!,
        videoRatio: LocationCardData.map1["videoRatio"]!,
        videoUri: LocationCardData.map1["videoUri"]!,
      )
    ];
    return items;
  }
}
