import 'dart:async';
import 'package:flutter/material.dart';
import 'create_group_screen.dart';
import 'view_meetings_screen.dart';
import 'map_screen.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Timer? _locationUpdateTimer;

  static final List<Widget> _widgetOptions = <Widget>[
    const MapScreen(
      meetingName: '',
    ),
    const CreateGroupScreen(),
    const ViewMeetingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (Timer timer) async {
      try {
        Position position = await _getCurrentLocation();
        await _updateUserLocation(position);
      } catch (e) {
        debugPrint('Error updating location: $e');
      }
    });
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      } else if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _updateUserLocation(Position position) async {
    try {
      final response = await ApiService.post('/update_location/', {
        'latitude': position.latitude,
        'longitude': position.longitude,
      }, requireAuth: true);

      if (response.statusCode == 200) {
        debugPrint('Location updated successfully.');
      } else {
        debugPrint('Failed to update location: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error during location update: $e');
    }
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_add_outlined),
              activeIcon: Icon(Icons.group_add),
              label: 'Create Group',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.meeting_room_outlined),
              activeIcon: Icon(Icons.meeting_room),
              label: 'Meetings',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: const Color(0xFF64748B),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
