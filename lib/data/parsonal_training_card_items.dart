import 'package:four_secrets_wedding_app/data/personal_training_card_data.dart';
import 'package:four_secrets_wedding_app/model/card_front_widget.dart';
import 'package:flutter/material.dart';

class PersonalTrainingCardItems {
  static List getCardItems() {
    List<Widget> items = [
      CardWidget(
        className: PersonalTrainingCardData,
        avatarImage: PersonalTrainingCardData.map1['avatar']!,
        vorname: PersonalTrainingCardData.map1['vorname']!,
        nachname: PersonalTrainingCardData.map1['nachname']!,
        bezeichnung: PersonalTrainingCardData.map1['bezeichnung']!,
        backCardTaetigkeit:
            PersonalTrainingCardData.map1['backCardTaetigkeit']!,
        slogan: PersonalTrainingCardData.map1["slogan"]!,
        homepage: PersonalTrainingCardData.map1['homepage']!,
        email: PersonalTrainingCardData.map1['email']!,
        instagram: PersonalTrainingCardData.map1["instagram"]!,
        phoneNumber: PersonalTrainingCardData.map1["phoneNumber"]!,
        videoAsset: PersonalTrainingCardData.map1["videoAsset"]!,
        videoRatio: PersonalTrainingCardData.map1["videoRatio"]!,
        videoUri: PersonalTrainingCardData.map1["videoUri"]!,
      )
    ];
    return items;
  }
}
