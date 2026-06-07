import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api_service.dart';

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
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(37.7749, -122.4194); // Default to SF
  final Set<Marker> _markers = {};
  bool _locationLoaded = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();

    if (widget.latitude != null && widget.longitude != null) {
      LatLng finalizedPosition = LatLng(widget.latitude!, widget.longitude!);
      _markers.add(
        Marker(
          markerId: const MarkerId('finalized_location'),
          position: finalizedPosition,
          infoWindow: InfoWindow(
            title: widget.meetingName.isEmpty ? "Meeting Location" : widget.meetingName,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
      _currentPosition = finalizedPosition;
    }
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location services are disabled. Please enable them.")),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permissions are denied. Please grant permissions.")),
          );
        }
        return;
      }
    }

    _getCurrentLocation();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_locationLoaded || (widget.latitude != null && widget.longitude != null)) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition, 12));
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
          _markers.add(Marker(
            markerId: const MarkerId('current_location'),
            position: _currentPosition,
            infoWindow: const InfoWindow(title: 'You are here'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ));
          _locationLoaded = true;
          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition, 14));
        });
      }
    } catch (e) {
      debugPrint("Failed to get current location: $e");
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      final response = await ApiService.post('/logout/', {}, requireAuth: true);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('access_token');
        const storage = FlutterSecureStorage();
        await storage.delete(key: 'jwt_token');

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logout failed: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meetingName.isEmpty ? "MinuteMeet Map" : widget.meetingName, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          _isLoggingOut
              ? const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
              : IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _logout,
                  tooltip: 'Logout',
                ),
        ],
      ),
      body: SafeArea(
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 10,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.my_location, color: Colors.white),
        onPressed: () {
          if (_locationLoaded) {
             _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition, 14));
          } else {
             _getCurrentLocation();
          }
        },
      ),
    );
  }
}
