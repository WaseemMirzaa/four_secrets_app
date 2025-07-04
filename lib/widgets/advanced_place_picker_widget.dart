import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdvancedPlacePickerWidget extends StatefulWidget {
  final double? initialLat;
  final double? initialLong;
  final String? initialAddress;

  const AdvancedPlacePickerWidget({
    Key? key,
    this.initialLat,
    this.initialLong,
    this.initialAddress,
  }) : super(key: key);

  @override
  State<AdvancedPlacePickerWidget> createState() =>
      _AdvancedPlacePickerWidgetState();
}

class _AdvancedPlacePickerWidgetState extends State<AdvancedPlacePickerWidget> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool isLoading = false;
  List<dynamic> _placePredictions = [];
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  String _sessionToken = '';
  static const String _googleApiKey = "AIzaSyDR_QZaW3xiJfLLNFybEd6e6HunqDkUjJg";
  CameraPosition? _cameraPosition;

  @override
  void initState() {
    super.initState();
    if ((widget.initialLat == null || widget.initialLat == 0) &&
        (widget.initialLong == null || widget.initialLong == 0)) {
      _getCurrentLocation();
    } else {
      _selectedLocation =
          LatLng(widget.initialLat ?? 0, widget.initialLong ?? 0);
      _selectedAddress = widget.initialAddress ?? '';
      _cameraPosition = CameraPosition(target: _selectedLocation!, zoom: 15);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoading = true;
    });
    await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _selectedLocation = LatLng(position.latitude, position.longitude);
    _cameraPosition = CameraPosition(target: _selectedLocation!, zoom: 15);
    await _getAddressFromLatLng(_selectedLocation!);
    setState(() {
      isLoading = false;
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
          _selectedAddress = formatted;
        });
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
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(position, 16),
      );
      setState(() {
        _selectedLocation = position;
        _selectedAddress = address;
        _searchController.text = address;
        _placePredictions = [];
        _cameraPosition = CameraPosition(target: position, zoom: 15);
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = const Color.fromARGB(255, 107, 69, 106);
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('Standort auswählen'),
        backgroundColor: mainColor,
      ),
      body: isLoading || _selectedLocation == null
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (controller) => _mapController = controller,
                  initialCameraPosition: _cameraPosition!,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  onCameraMove: (position) {
                    _cameraPosition = position;
                  },
                  onCameraIdle: () async {
                    if (_cameraPosition != null) {
                      _selectedLocation = _cameraPosition!.target;
                      await _getAddressFromLatLng(_selectedLocation!);
                    }
                  },
                  markers: {}, // No marker, we use a center pin
                ),
                // Center pin with radius effect
                IgnorePointer(
                  ignoring: true,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: mainColor.withValues(alpha: 0.18),
                          ),
                        ),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: mainColor.withValues(alpha: 0.12),
                          ),
                        ),
                        Icon(
                          Icons.location_on,
                          size: 56,
                          color: mainColor,
                        ),
                      ],
                    ),
                  ),
                ),
                // Search bar
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          filled: true,
                          hintText: "Suche Standort...",
                          fillColor: Colors.white,
                          prefixIcon: Icon(
                            FontAwesomeIcons.magnifyingGlass,
                            size: 16,
                          ),
                          border:
                              OutlineInputBorder(borderSide: BorderSide.none),
                        ),
                        onChanged: (value) {
                          _fetchPlacePredictions(value);
                        },
                        onTap: () {
                          if (_placePredictions.isNotEmpty) _showOverlay();
                        },
                        onEditingComplete: () {
                          _removeOverlay();
                        },
                      ),
                    ),
                  ),
                ),
                // Address display and swipe-to-select button
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 18),
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
                        CustomTextWidget(
                          text: _selectedAddress,
                          fontSize: 14,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onHorizontalDragEnd: (details) {
                              Navigator.pop(context, {
                                "lat": _selectedLocation!.latitude,
                                "long": _selectedLocation!.longitude,
                                "address": _selectedAddress,
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: mainColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: const CustomTextWidget(
                                text: "Standort bestätigen",
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
