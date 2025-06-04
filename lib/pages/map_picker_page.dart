import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/model/checklist_button.dart';
import 'package:four_secrets_wedding_app/models/location_suggestions_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/place_type.dart';
import 'package:google_places_flutter/model/prediction.dart';

class MapSelectionPage extends StatefulWidget {
  final String address;
  final double lat;
  final double long;

  const MapSelectionPage({
    super.key,
    required this.address,
    required this.lat,
    required this.long,
  });

  @override
  State<MapSelectionPage> createState() => _MapSelectionPageState();
}

class _MapSelectionPageState extends State<MapSelectionPage> {
  late GoogleMapController _mapController;
  late LatLng _selectedLocation;
  late String _selectedAddress;
  final Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();
   bool isloading = false;

  @override 
  void initState() {
    super.initState();
    if(widget.address.isEmpty && widget.lat == 0 && widget.long == 0){
     getLocation();

    } else {
    _selectedLocation = LatLng(widget.lat, widget.long);
    _selectedAddress = widget.address;

    _addMarker(_selectedLocation, _selectedAddress);
    }
  }


getLocation() async {
  setState(() {
    isloading = true;
  });
  await Geolocator.requestPermission();
  
  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  double lat = position.latitude;
  double long = position.longitude;

  LatLng location = LatLng(lat, long);

  // Get address from coordinates
  List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);
  String address = '';
  if (placemarks.isNotEmpty) {
    Placemark place = placemarks[0];
    address =
        "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
  }

  setState(() {
    _selectedLocation = location;
    _selectedAddress = address;
    isloading = false;

  });

    setState(() {
      isloading = false;
    });
  _addMarker(location, address);
}

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addMarker(LatLng position, String address) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected-location'),
          position: position,
          infoWindow: InfoWindow(title: address),
        ),
      );
    });
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final formatted = [
          place.name,
          place.street,
          place.locality,
          place.administrativeArea,
          place.country
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        setState(() {
          _selectedLocation = position;
          _selectedAddress = formatted;
          _searchController.text = _selectedAddress;
        });

        _addMarker(position, formatted);
      }
    } catch (e) {
      debugPrint('Error fetching address: $e');
    }
  }

  Future<void> _searchAndNavigate() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final position = LatLng(loc.latitude, loc.longitude);

        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(position, 16),
        );

        await _getAddressFromLatLng(position);
      }
    } catch (e) {
      debugPrint('Error searching location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location not found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          centerTitle: true,
          foregroundColor: Colors.white,
            title: const Text('Standort auswählen'),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        ),
      body: isloading ? Center(child: CircularProgressIndicator(),)  : Stack(
        children: [
          
          Column(
            children: [
              Expanded(
                child: GoogleMap(
                  onMapCreated: (controller) => _mapController = controller,
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: 15,
                  ),
                  markers: _markers,
                  onTap: (position) async {
                    _mapController.animateCamera(
                      CameraUpdate.newLatLng(position),
                    );
                    setState(() {
                     
                    });
                    await _getAddressFromLatLng(position);
                  },
                ),
              ),
               Container(
                
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Ausgewählte Adresse:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedAddress,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: MyButton(
                        onPressed: () {
                          Navigator.pop(context, {
                            "lat": _selectedLocation.latitude,
                            "long": _selectedLocation.longitude,
                            "address": _selectedAddress,
                          });
                        },
                        color: const Color.fromARGB(255, 107, 69, 106),
                        textColor: Colors.white,
                        text: "Standort bestätigen",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
         
         Padding(
  padding: const EdgeInsets.all(8.0),
  child: Container(
    height: 60,
    width: context.screenWidth,
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10)
    ),
    child: GooglePlaceAutoCompleteTextField(

            textEditingController: _searchController,
            googleAPIKey: "AIzaSyDR_QZaW3xiJfLLNFybEd6e6HunqDkUjJg",
            inputDecoration: InputDecoration(
              filled: true,
              hintText: "Suche Standort...",
               
              fillColor: Colors.white,
              prefixIcon: Icon(FontAwesomeIcons.magnifyingGlass, size: 16,),
              border: OutlineInputBorder(
                borderSide: BorderSide.none
              ), 
              
            ),
            debounceTime: 500,
            isLatLngRequired: true,
            getPlaceDetailWithLatLng: (Prediction prediction) {
              print("placeDetails" + prediction.lng.toString());
            },
            itemClick: (Prediction prediction) {
              _searchController.text = prediction.description!;
              _searchController.selection = TextSelection.fromPosition(
                TextPosition(offset: prediction.description!.length),
              );
              _selectedAddress = _searchController.text;
              _searchAndNavigate();
            },
            itemBuilder: (context, index, Prediction prediction) {
              return Container(
                padding: EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(Icons.location_on),
                    SizedBox(width: 7),
                    Expanded(child: Text("${prediction.description ?? ""}")),
                  ],
                ),
              );
            },
            seperatedBuilder: Divider(),
            isCrossBtnShown: true,
            containerHorizontalPadding: 10,
            placeType: PlaceType.geocode,
          ),
  ),
    
),
        ],
      ),
    );
  }
}
