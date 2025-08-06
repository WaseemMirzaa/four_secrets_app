import 'package:four_secrets_wedding_app/data/band_dj_card_data.dart';
import 'package:four_secrets_wedding_app/model/card_front_widget.dart';
import 'package:flutter/material.dart';

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
        slogan: BandDjCardData.map1['slogan']!,
        homepage: BandDjCardData.map1['homepage']!,
        email: BandDjCardData.map1["email"]!,
        instagram: BandDjCardData.map1["instagram"]!,
        phoneNumber: BandDjCardData.map1["phoneNumber"]!,
        videoAsset: BandDjCardData.map1["videoAsset"]!,
        videoRatio: BandDjCardData.map1["videoRatio"]!,
        videoUri: BandDjCardData.map1["videoUri"]!,
      ),
      CardWidget(
        className: BandDjCardData,
        avatarImage: BandDjCardData.map2['avatar']!,
        vorname: BandDjCardData.map2['vorname']!,
        nachname: BandDjCardData.map2['nachname']!,
        bezeichnung: BandDjCardData.map2['bezeichnung']!,
        backCardTaetigkeit: BandDjCardData.map2['backCardTaetigkeit']!,
        slogan: BandDjCardData.map2['slogan']!,
        homepage: BandDjCardData.map2['homepage']!,
        email: BandDjCardData.map2["email"]!,
        instagram: BandDjCardData.map2["instagram"]!,
        phoneNumber: BandDjCardData.map2["phoneNumber"]!,
        videoAsset: BandDjCardData.map2["videoAsset"]!,
        videoRatio: BandDjCardData.map2["videoRatio"]!,
        videoUri: BandDjCardData.map2["videoUri"]!,
      ),
      CardWidget(
        className: BandDjCardData,
        avatarImage: BandDjCardData.map3['avatar']!,
        vorname: BandDjCardData.map3['vorname']!,
        nachname: BandDjCardData.map3['nachname']!,
        bezeichnung: BandDjCardData.map3['bezeichnung']!,
        backCardTaetigkeit: BandDjCardData.map3['backCardTaetigkeit']!,
        slogan: BandDjCardData.map3['slogan']!,
        homepage: BandDjCardData.map3['homepage']!,
        email: BandDjCardData.map3["email"]!,
        instagram: BandDjCardData.map3["instagram"]!,
        phoneNumber: BandDjCardData.map3["phoneNumber"]!,
        videoAsset: BandDjCardData.map3["videoAsset"]!,
        videoRatio: BandDjCardData.map3["videoRatio"]!,
        videoUri: BandDjCardData.map3["videoUri"]!,
      ),
    ];
    return items;
  }
}
