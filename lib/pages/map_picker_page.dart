import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/widgets/advanced_place_picker_widget.dart';

class MapSelectionPage extends StatelessWidget {
  final String address;
  final double lat;
  final double long;

  const MapSelectionPage({
    Key? key,
    required this.address,
    required this.lat,
    required this.long,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdvancedPlacePickerWidget(
      initialAddress: address,
      initialLat: lat,
      initialLong: long,
    );
  }
}
