import 'package:four_secrets_wedding_app/data/wedding_designer_card_data.dart';
import 'package:four_secrets_wedding_app/model/card_front_widget.dart';
import 'package:flutter/material.dart';

class WeddingDesignerCardItems {
  static List getCardItems() {
    List<Widget> items = [
      CardWidget(
        className: WeddingDesignerCardData,
        avatarImage: WeddingDesignerCardData.map1['avatar']!,
        vorname: WeddingDesignerCardData.map1['vorname']!,
        nachname: WeddingDesignerCardData.map1['nachname']!,
        bezeichnung: WeddingDesignerCardData.map1['bezeichnung']!,
        backCardTaetigkeit: WeddingDesignerCardData.map1['backCardTaetigkeit']!,
        backCardAdress1: WeddingDesignerCardData.map1['backCardAdresse1']!,
        backCardAdress2: WeddingDesignerCardData.map1['backCardAdresse2']!,
        homepage: WeddingDesignerCardData.map1['homepage']!,
        email: WeddingDesignerCardData.map1['email']!,
        instagram: WeddingDesignerCardData.map1["instagram"]!,
        phoneNumber: WeddingDesignerCardData.map1["phoneNumber"]!,
        videoAsset: WeddingDesignerCardData.map1["videoAsset"]!,
        videoRatio: WeddingDesignerCardData.map1["videoRatio"]!,
        videoUri: WeddingDesignerCardData.map1["videoUri"]!,
      ),
      CardWidget(
        className: WeddingDesignerCardData,
        avatarImage: WeddingDesignerCardData.map2['avatar']!,
        vorname: WeddingDesignerCardData.map2['vorname']!,
        nachname: WeddingDesignerCardData.map2['nachname']!,
        bezeichnung: WeddingDesignerCardData.map2['bezeichnung']!,
        backCardTaetigkeit: WeddingDesignerCardData.map2['backCardTaetigkeit']!,
        backCardAdress1: WeddingDesignerCardData.map2['backCardAdresse1']!,
        backCardAdress2: WeddingDesignerCardData.map2['backCardAdresse2']!,
        homepage: WeddingDesignerCardData.map2['homepage']!,
        email: WeddingDesignerCardData.map2['email']!,
        instagram: WeddingDesignerCardData.map2["instagram"]!,
        phoneNumber: WeddingDesignerCardData.map2["phoneNumber"]!,
        videoAsset: WeddingDesignerCardData.map2["videoAsset"]!,
        videoRatio: WeddingDesignerCardData.map2["videoRatio"]!,
        videoUri: WeddingDesignerCardData.map2["videoUri"]!,
      ),
      CardWidget(
        className: WeddingDesignerCardData,
        avatarImage: WeddingDesignerCardData.map3['avatar']!,
        vorname: WeddingDesignerCardData.map3['vorname']!,
        nachname: WeddingDesignerCardData.map3['nachname']!,
        bezeichnung: WeddingDesignerCardData.map3['bezeichnung']!,
        backCardTaetigkeit: WeddingDesignerCardData.map3['backCardTaetigkeit']!,
        backCardAdress1: WeddingDesignerCardData.map3['backCardAdresse1']!,
        backCardAdress2: WeddingDesignerCardData.map3['backCardAdresse2']!,
        homepage: WeddingDesignerCardData.map3['homepage']!,
        email: WeddingDesignerCardData.map3['email']!,
        instagram: WeddingDesignerCardData.map3["instagram"]!,
        phoneNumber: WeddingDesignerCardData.map3["phoneNumber"]!,
        videoAsset: WeddingDesignerCardData.map3["videoAsset"]!,
        videoRatio: WeddingDesignerCardData.map3["videoRatio"]!,
        videoUri: WeddingDesignerCardData.map3["videoUri"]!,
      )
    ];
    return items;
  }
}
