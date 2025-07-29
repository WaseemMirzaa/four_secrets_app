import 'package:four_secrets_wedding_app/data/kosmetische_akupunktur_card_data.dart';
import 'package:four_secrets_wedding_app/model/card_front_widget.dart';
import 'package:flutter/material.dart';

class KosmetischeAkupunkturCardItems {
  static List getCardItems() {
    List<Widget> items = [
      CardWidget(
        className: KosmetischeAkupunkturCardData,
        avatarImage: KosmetischeAkupunkturCardData.map1['avatar']!,
        vorname: KosmetischeAkupunkturCardData.map1['vorname']!,
        nachname: KosmetischeAkupunkturCardData.map1['nachname']!,
        bezeichnung: KosmetischeAkupunkturCardData.map1['bezeichnung']!,
        backCardTaetigkeit:
            KosmetischeAkupunkturCardData.map1['backCardTaetigkeit']!,
        slogan: KosmetischeAkupunkturCardData.map1['slogan']!,
        homepage: KosmetischeAkupunkturCardData.map1['homepage']!,
        email: KosmetischeAkupunkturCardData.map1["email"]!,
        instagram: KosmetischeAkupunkturCardData.map1["instagram"]!,
        phoneNumber: KosmetischeAkupunkturCardData.map1["phoneNumber"]!,
        videoAsset: KosmetischeAkupunkturCardData.map1["videoAsset"]!,
        videoRatio: KosmetischeAkupunkturCardData.map1["videoRatio"]!,
        videoUri: KosmetischeAkupunkturCardData.map1["videoUri"]!,
      )
    ];
    return items;
  }
}
