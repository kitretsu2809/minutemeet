import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/api_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  List<Contact> _selectedContacts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required to create meetings.')),
          );
        }
      }
    }
  }

  void _selectContacts() async {
    if (await Permission.contacts.request().isGranted) {
      final List<Contact> contacts = await FlutterContacts.getContacts(withProperties: true);
      List<Contact> selectedContacts = List.from(_selectedContacts);

      if (!mounted) return;
      final result = await showDialog<List<Contact>>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Select up to 4 Contacts'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    shrinkWrap: true,
                    children: contacts.map((contact) {
                      bool isSelected = selectedContacts.contains(contact);
                      return CheckboxListTile(
                        title: Text(contact.displayName ?? 'Unknown'),
                        subtitle: Text(contact.phones.isNotEmpty == true ? contact.phones.first.number : 'No phone number'),
                        value: isSelected,
                        onChanged: (bool? selected) {
                          setState(() {
                            if (selected == true) {
                              if (selectedContacts.length < 4) {
                                selectedContacts.add(contact);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('You can only select up to 4 contacts.')),
                                );
                              }
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
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts permission is required.')),
        );
      }
    }
  }

  Future<void> _createGroup() async {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();

      String cleanPhoneNumber(String phone) {
        phone = phone.replaceAll(RegExp(r'\s+'), '');
        phone = phone.replaceAll(RegExp(r'\D'), ''); // Remove all non-digits
        // Optional: Remove country code if you enforce strict local numbers, 
        // but it's better to keep backend matching flexible. Let's assume backend takes 10 digits or full.
        if (phone.length > 10 && phone.startsWith('91')) {
           phone = phone.substring(2);
        }
        return phone;
      }

      final userPhones = _selectedContacts
          .map((contact) => contact.phones.isNotEmpty
              ? cleanPhoneNumber(contact.phones.first.number)
              : '')
          .where((phone) => phone.isNotEmpty)
          .toList();

      if (userPhones.isEmpty || userPhones.length > 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select between 1 to 4 valid contacts with phone numbers.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final response = await ApiService.post('/create-group/', {
          'name': name,
          'user_phones': userPhones,
        }, requireAuth: true);

        if (response.statusCode == 201) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group & Meeting created successfully!'), backgroundColor: Colors.green),
          );
          setState(() {
            _nameController.clear();
            _selectedContacts.clear();
          });
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create group: ${response.body}')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Group")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Icon(
                  Icons.group_add,
                  size: 64,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(height: 24.0),
                const Text(
                  'Start a Meeting',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 32.0),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Meeting/Group Name',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a group name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                ElevatedButton.icon(
                  onPressed: _selectContacts,
                  icon: const Icon(Icons.contacts_outlined),
                  label: const Text('Select Friends from Contacts'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF2563EB)),
                  ),
                ),
                const SizedBox(height: 16.0),
                if (_selectedContacts.isNotEmpty) ...[
                  const Text(
                    'Selected Contacts:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    children: _selectedContacts.map((contact) {
                      return Chip(
                        label: Text(contact.displayName ?? 'Unknown'),
                        onDeleted: () {
                          setState(() {
                            _selectedContacts.remove(contact);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24.0),
                ],
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _createGroup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Create Meeting Group', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
