class CreateMeeting {
  final String name;
  final List<String> userPhones;

  CreateMeeting({
    required this.name,
    required this.userPhones,
  });

  factory CreateMeeting.fromJson(Map<String, dynamic> json) {
    return CreateMeeting(
      name: json['name'],
      userPhones: List<String>.from(json['user_phones']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'user_phones': userPhones,
    };
  }
}
