import 'package:four_secrets_wedding_app/data/trauringe_card_data.dart';
import 'package:four_secrets_wedding_app/model/card_front_widget.dart';
import 'package:flutter/material.dart';

class TrauringeCardItems {
  static List getCardItems() {
    List<Widget> items = [
      CardWidget(
        className: TrauringeCardData,
        avatarImage: TrauringeCardData.map1['avatar']!,
        vorname: TrauringeCardData.map1['vorname']!,
        nachname: TrauringeCardData.map1['nachname']!,
        bezeichnung: TrauringeCardData.map1['bezeichnung']!,
        backCardTaetigkeit: TrauringeCardData.map1['backCardTaetigkeit']!,
        slogan: TrauringeCardData.map1['slogan']!,
        homepage: TrauringeCardData.map1['homepage']!,
        email: TrauringeCardData.map1['email']!,
        instagram: TrauringeCardData.map1["instagram"]!,
        phoneNumber: TrauringeCardData.map1["phoneNumber"]!,
        videoAsset: TrauringeCardData.map1["videoAsset"]!,
        videoRatio: TrauringeCardData.map1["videoRatio"]!,
        videoUri: TrauringeCardData.map1["videoUri"]!,
      ),
    ];
    return items;
  }
}
