import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

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
                  : widget.meetingName),
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
        // ignore: deprecated_member_use
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

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("MinuteMeet")),
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
