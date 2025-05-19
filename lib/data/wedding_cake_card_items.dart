import 'package:four_secrets_wedding_app/data/wedding_cake_card_data.dart';
import 'package:four_secrets_wedding_app/model/card_front_widget.dart';
import 'package:flutter/material.dart';

class WeddingCakeItems {
  static List getCardItems() {
    List<Widget> items = [
      CardWidget(
        className: WeddingCakeData,
        avatarImage: WeddingCakeData.map1['avatar']!,
        vorname: WeddingCakeData.map1['vorname']!,
        nachname: WeddingCakeData.map1['nachname']!,
        bezeichnung: WeddingCakeData.map1['bezeichnung']!,
        backCardTaetigkeit: WeddingCakeData.map1['backCardTaetigkeit']!,
        backCardAdress1: WeddingCakeData.map1['backCardAdresse1']!,
        backCardAdress2: WeddingCakeData.map1['backCardAdresse2']!,
        homepage: WeddingCakeData.map1['homepage']!,
        email: WeddingCakeData.map1['email']!,
        instagram: WeddingCakeData.map1["instagram"]!,
        phoneNumber: WeddingCakeData.map1["phoneNumber"]!,
        videoAsset: WeddingCakeData.map1["videoAsset"]!,
        videoRatio: WeddingCakeData.map1["videoRatio"]!,
        videoUri: WeddingCakeData.map1["videoUri"]!,
      )
    ];
    return items;
  }
}
