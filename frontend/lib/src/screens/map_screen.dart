import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http; // Import the http package

class MapScreen extends StatefulWidget {
  final String meetingName;
  final double? latitude;
  final double? longitude;

  const MapScreen({
    super.key,
    required this.meetingName,
    this.latitude,
    this.longitude,
  });

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  LatLng _currentPosition =
      const LatLng(37.7749, -122.4194); // Default to San Francisco
  final Set<Marker> _markers = {};
  bool _locationLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();

    // If the finalized meeting location is provided, add a marker for it
    if (widget.latitude != null && widget.longitude != null) {
      LatLng finalizedPosition = LatLng(widget.latitude!, widget.longitude!);
      _markers.add(
        Marker(
          markerId: const MarkerId('finalized_location'),
          position: finalizedPosition,
          infoWindow: InfoWindow(
            title: widget.meetingName.isEmpty
                ? "Meeting Location"
                : widget.meetingName,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );

      // Set the initial position to the finalized location
      _currentPosition = finalizedPosition;
    }
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Location services are disabled. Please enable them.")),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    "Location permissions are denied. Please grant permissions.")),
          );
        }
        return;
      }
    }

    _getCurrentLocation();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_locationLoaded ||
        widget.latitude != null && widget.longitude != null) {
      _mapController
          .animateCamera(CameraUpdate.newLatLngZoom(_currentPosition, 12));
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          print(
              'Current Location: ${_currentPosition.latitude}, ${_currentPosition.longitude}');
          _markers.add(Marker(
            markerId: const MarkerId('current_location'),
            position: _currentPosition,
            infoWindow: const InfoWindow(title: 'Current Location'),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ));
          _locationLoaded = true;
          _mapController
              .animateCamera(CameraUpdate.newLatLngZoom(_currentPosition, 12));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to get current location: $e")),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      final response = await http.post(
        Uri.parse(
            'http://192.168.100.228:8000/logout/'), // Using the correct http package
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        // Handle successful logout
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logout failed: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MinuteMeet"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _currentPosition,
          zoom: 10,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _markers,
      ),
    );
  }
}
