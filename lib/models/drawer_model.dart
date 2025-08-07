import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DrawerModel {
  final String name;
  final IconData? icon;
  final String? customIconPath;

  DrawerModel({
    required this.name,
    this.icon,
    this.customIconPath,
  }) : assert(icon != null || customIconPath != null,
            'Either icon or customIconPath must be provided');
}

List<DrawerModel> listDrawerModel = [
  DrawerModel(name: "Home", icon: Icons.home),
  DrawerModel(name: "Münchner Geheimtipp", icon: Icons.auto_stories),
  DrawerModel(
      name: "Eigene Dienstleister", customIconPath: "assets/icons/person1.png"),
  DrawerModel(name: "Budget", icon: Icons.euro_rounded),
  DrawerModel(name: "Checkliste", icon: Icons.checklist),
  DrawerModel(name: "Gästeliste", icon: Icons.group),
  DrawerModel(name: "Tischverwaltung", icon: Icons.table_bar),
  DrawerModel(name: "Tagesablauf", icon: FontAwesomeIcons.solidClock),
  DrawerModel(name: "Inspirationen", icon: FontAwesomeIcons.solidLightbulb),
  DrawerModel(name: "Hochzeitskit", icon: FontAwesomeIcons.listCheck),
  DrawerModel(name: "Mitgestalter", icon: FontAwesomeIcons.peopleGroup),
  DrawerModel(name: "KI-Assistent", icon: FontAwesomeIcons.robot),
  DrawerModel(name: "Showroom", icon: Icons.celebration),
  DrawerModel(name: "Über mich", icon: Icons.account_box_sharp),
  DrawerModel(name: "Kontakt", icon: FontAwesomeIcons.mapLocationDot),
  DrawerModel(name: "Impressum", icon: FontAwesomeIcons.circleInfo),
];
