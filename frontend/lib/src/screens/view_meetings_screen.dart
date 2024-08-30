import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/meeting.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './map_screen.dart'; // Import MapScreen if it's in another file

Future<List<Meeting>> fetchMeetings() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  if (token == null) {
    throw Exception('No token found');
  }

  print("Using token: $token"); // Debug print

  final response = await http.get(
    Uri.parse('http://192.168.100.228:8000/user/meetings'),
    headers: {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );

  print("Response status: ${response.statusCode}");
  print("Response body: ${response.body}");

  if (response.statusCode == 200) {
    // Parse and return meetings
    List<dynamic> jsonResponse = json.decode(response.body);
    return jsonResponse.map((data) => Meeting.fromJson(data)).toList();
  } else if (response.statusCode == 401) {
    throw Exception('Unauthorized: Token may be invalid or expired');
  } else {
    throw Exception('Failed to load meetings: ${response.statusCode}');
  }
}

class ViewMeetingsScreen extends StatefulWidget {
  const ViewMeetingsScreen({Key? key}) : super(key: key);

  @override
  _ViewMeetingsScreenState createState() => _ViewMeetingsScreenState();
}

class _ViewMeetingsScreenState extends State<ViewMeetingsScreen> {
  Future<List<Meeting>>? _futureMeetings;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    print("Loaded token: $token"); // Debug print

    setState(() {
      _token = token;
      _futureMeetings = fetchMeetings();
    });
  }

  Future<void> _refreshMeetings() async {
    await _loadToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meetings"),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshMeetings,
        child: _buildMeetingsList(),
      ),
    );
  }

  Widget _buildMeetingsList() {
    return FutureBuilder<List<Meeting>>(
      future: _futureMeetings,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: _refreshMeetings,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No meetings available'));
        }

        final meetings = snapshot.data!;
        return ListView.builder(
          itemCount: meetings.length,
          itemBuilder: (context, index) {
            final meeting = meetings[index];
            return ListTile(
              title: Text(meeting.name),
              subtitle: meeting.date != null
                  ? Text(DateFormat.yMMMd().format(meeting.date!))
                  : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapScreen(
                      meetingName: meeting.name,
                      latitude: meeting.finalizedLatitude,
                      longitude: meeting.finalizedLongitude,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
