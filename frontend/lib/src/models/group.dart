class CreateGroup {
  final String name;
  final List<String> userPhones;

  CreateGroup({
    required this.name,
    required this.userPhones,
  });

  factory CreateGroup.fromJson(Map<String, dynamic> json) {
    return CreateGroup(
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