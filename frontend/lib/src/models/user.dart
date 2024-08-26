class User {
  final String username;
  final String password;
  final String email;
  final String phone;
  final String location;
  final double latitude;
  final double longitude;

  User({
    required this.username,
    required this.password,
    required this.email,
    required this.phone,
    required this.location,
    required this.latitude,
    required this.longitude,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      password: json['password'],
      email: json['email'],
      phone: json['phone'],
      location: json['location'],
      latitude: (json['latitude'] ?? 0.0) as double,
      longitude: (json['longitude'] ?? 0.0) as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'email': email,
      'phone': phone,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
