



//   import 'package:flutter/material.dart';
// import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';

// showDiaLogMap(BuildContext context)async{
//     showDialog(context: context, 
//     builder: (_)
//     {
//       return FlutterLocationPicker(
//         initPosition: LatLong(23, 89),
//         selectLocationButtonStyle: ButtonStyle(
//           backgroundColor: WidgetStateProperty.all(Colors.blue),
//         ),
//         // selectedLocationButtonTextstyle: const TextStyle(fontSize: 18),
//         selectLocationButtonText: 'Set Current Location',
//         selectLocationButtonLeadingIcon: const Icon(Icons.check),
//         initZoom: 11,
//         minZoomLevel: 5,
//         maxZoomLevel: 16,
//         trackMyPosition: true,
//         onError: (e) => print(e),
//         onPicked: (pickedData) {
//           print(pickedData.latLong.latitude);
//           print(pickedData.latLong.longitude);
//           print(pickedData.address);
//           print(pickedData.addressData['country']);
//         },
//         onChanged: (pickedData) {
//           print(pickedData.latLong.latitude);
//           print(pickedData.latLong.longitude);
//           print(pickedData.address);
//           print(pickedData.addressData);
//         });
//     });
//   }