import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DrawerModel {
final String name;
final IconData icon;


DrawerModel({
  required this.name,
  required this.icon,
});

}

List<DrawerModel> listDrawerModel = [
  DrawerModel(name: "Home", icon:  Icons.home),
  DrawerModel(name: "Inspirationen", icon: Icons.auto_stories),
  DrawerModel(name: "Checkliste", icon: Icons.checklist),
  DrawerModel(name: "Budget", icon: Icons.euro_rounded),
  DrawerModel(name: "Gästeliste", icon: Icons.group),
  DrawerModel(name: "Tischverwaltung", icon: Icons.table_bar),
  DrawerModel(name: "Showroom", icon: Icons.celebration),
  DrawerModel(name: "Über mich", icon: Icons.account_box_sharp),
  DrawerModel(name: "Kontakt", icon: FontAwesomeIcons.mapLocationDot),
  DrawerModel(name: "Impressum", icon: FontAwesomeIcons.circleInfo),
  DrawerModel(name: "Inspirationsordner", icon:  FontAwesomeIcons.solidLightbulb),

];