import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlacePickerWidget extends StatefulWidget {
  final String? initialAddress;
  final double? initialLat;
  final double? initialLong;

  const PlacePickerWidget({
    Key? key,
    this.initialAddress,
    this.initialLat,
    this.initialLong,
  }) : super(key: key);

  @override
  State<PlacePickerWidget> createState() => _PlacePickerWidgetState();
}

class _PlacePickerWidgetState extends State<PlacePickerWidget> {
  late GoogleMapController _mapController;
  late LatLng _selectedLocation;
  late String _selectedAddress;
  final Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool isLoading = false;
  List<dynamic> _placePredictions = [];
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  String _sessionToken = '';
  static const String _googleApiKey = "AIzaSyDR_QZaW3xiJfLLNFybEd6e6HunqDkUjJg";

  @override
  void initState() {
    super.initState();
    if ((widget.initialAddress?.isEmpty ?? true) &&
        (widget.initialLat == null || widget.initialLat == 0) &&
        (widget.initialLong == null || widget.initialLong == 0)) {
      getLocation();
    } else {
      _selectedLocation =
          LatLng(widget.initialLat ?? 0, widget.initialLong ?? 0);
      _selectedAddress = widget.initialAddress ?? '';
      _addMarker(_selectedLocation, _selectedAddress);
    }
  }

  Future<void> getLocation() async {
    setState(() {
      isLoading = true;
    });
    await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    double lat = position.latitude;
    double long = position.longitude;
    LatLng location = LatLng(lat, long);
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
      isLoading = false;
    });
    _addMarker(location, address);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _removeOverlay();
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

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();
    if (_placePredictions.isEmpty || !_searchFocusNode.hasFocus) return;
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 16,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(8, 70),
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(10),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _placePredictions.length,
              itemBuilder: (context, index) {
                final prediction = _placePredictions[index];
                return ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text(prediction['description'] ?? ''),
                  onTap: () async {
                    _searchController.text = prediction['description'] ?? '';
                    _removeOverlay();
                    await _selectPrediction(prediction);
                    FocusScope.of(context).unfocus();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _fetchPlacePredictions(String input) async {
    if (input.isEmpty) {
      setState(() => _placePredictions = []);
      _removeOverlay();
      return;
    }
    if (_sessionToken.isEmpty) {
      _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
    }
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_googleApiKey&sessiontoken=$_sessionToken&language=de&components=country:de';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _placePredictions = data['predictions'] ?? [];
      });
      _showOverlay();
    } else {
      setState(() => _placePredictions = []);
      _removeOverlay();
    }
  }

  Future<void> _selectPrediction(dynamic prediction) async {
    final placeId = prediction['place_id'];
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleApiKey&sessiontoken=$_sessionToken&language=de';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final location = data['result']['geometry']['location'];
      final lat = location['lat'];
      final lng = location['lng'];
      final address = data['result']['formatted_address'];
      final position = LatLng(lat, lng);
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(position, 16),
      );
      setState(() {
        _selectedLocation = position;
        _selectedAddress = address;
        _searchController.text = address;
        _placePredictions = [];
      });
      _addMarker(position, address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('Standort auswählen'),
        backgroundColor: const Color.fromARGB(255, 107, 69, 106),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      GoogleMap(
                        onMapCreated: (controller) =>
                            _mapController = controller,
                        initialCameraPosition: CameraPosition(
                          target: _selectedLocation,
                          zoom: 15,
                        ),
                        markers: _markers,
                        onTap: (position) async {
                          _mapController.animateCamera(
                            CameraUpdate.newLatLng(position),
                          );
                          setState(() {});
                          await _getAddressFromLatLng(position);
                        },
                        zoomControlsEnabled: true,
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: CompositedTransformTarget(
                          link: _layerLink,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              decoration: InputDecoration(
                                filled: true,
                                hintText: "Suche Standort...",
                                fillColor: Colors.white,
                                prefixIcon: Icon(
                                  Icons.search,
                                  size: 16,
                                ),
                                border: OutlineInputBorder(
                                    borderSide: BorderSide.none),
                              ),
                              onChanged: (value) {
                                _fetchPlacePredictions(value);
                              },
                              onTap: () {
                                if (_placePredictions.isNotEmpty)
                                  _showOverlay();
                              },
                              onEditingComplete: () {
                                _removeOverlay();
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
                    mainAxisSize: MainAxisSize.min,
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
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, {
                              "lat": _selectedLocation.latitude,
                              "long": _selectedLocation.longitude,
                              "address": _selectedAddress,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 107, 69, 106),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Standort bestätigen"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
