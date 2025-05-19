import 'package:four_secrets_wedding_app/data/wedding_car_service_card_data.dart';
import 'package:four_secrets_wedding_app/model/card_front_widget.dart';
import 'package:flutter/material.dart';

class WeddingCarServiceItems {
  static List getCardItems() {
    List<Widget> items = [
      CardWidget(
        className: WeddingCarServiceData,
        avatarImage: WeddingCarServiceData.map1['avatar']!,
        vorname: WeddingCarServiceData.map1['vorname']!,
        nachname: WeddingCarServiceData.map1['nachname']!,
        bezeichnung: WeddingCarServiceData.map1['bezeichnung']!,
        backCardTaetigkeit: WeddingCarServiceData.map1['backCardTaetigkeit']!,
        backCardAdress1: WeddingCarServiceData.map1['backCardAdresse1']!,
        backCardAdress2: WeddingCarServiceData.map1['backCardAdresse2']!,
        homepage: WeddingCarServiceData.map1['homepage']!,
        email: WeddingCarServiceData.map1['email']!,
        instagram: WeddingCarServiceData.map1["instagram"]!,
        phoneNumber: WeddingCarServiceData.map1["phoneNumber"]!,
        videoAsset: WeddingCarServiceData.map1["videoAsset"]!,
        videoRatio: WeddingCarServiceData.map1["videoRatio"]!,
        videoUri: WeddingCarServiceData.map1["videoUri"]!,
      )
    ];
    return items;
  }
}
