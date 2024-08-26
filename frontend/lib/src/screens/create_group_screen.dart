import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:contacts_service/contacts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('jwt_token');
}

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  List<Contact> _selectedContacts = [];
  String _currentLocation = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          // ignore: deprecated_member_use
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = '${position.latitude}, ${position.longitude}';
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _selectContacts() async {
    final Iterable<Contact> contacts = await ContactsService.getContacts();
    List<Contact> selectedContacts = List.from(_selectedContacts);

    final result = await showDialog<List<Contact>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Contacts'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: contacts.map((contact) {
                    bool isSelected = selectedContacts.contains(contact);
                    return CheckboxListTile(
                      title: Text(contact.displayName ?? ''),
                      value: isSelected,
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            selectedContacts.add(contact);
                          } else {
                            selectedContacts.remove(contact);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('CANCEL'),
                  onPressed: () {
                    Navigator.of(context).pop(_selectedContacts);
                  },
                ),
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop(selectedContacts);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedContacts = result;
      });
      print(_selectedContacts);
    }
  }

  Future<void> _createGroup() async {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text;
      final userPhones = _selectedContacts
          .map((contact) => contact.phones!.isNotEmpty
              ? contact.phones!.first.value ?? ''
              : '')
          .where((phone) => phone.isNotEmpty)
          .toList();

      if (userPhones.length < 2 || userPhones.length > 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select between 2 to 4 phone numbers.')),
        );
        return;
      }
      final token = await getToken(); // Retrieve the JWT token
      print(token);
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/create-group/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'user_phones': userPhones,
        }),
      );
      print(userPhones);
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create group.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Group")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Group Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a group name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _selectContacts,
                  child: const Text('Select Contacts'),
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Selected Contacts: ${_selectedContacts.length}',
                  style: const TextStyle(fontSize: 16.0),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _createGroup,
                  child: const Text('Create Group'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
