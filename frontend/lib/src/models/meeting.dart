class Meeting {
  final String name;
  final DateTime? date;
  final double? finalizedLatitude;
  final double? finalizedLongitude;

  Meeting({
    required this.name,
    this.date,
    this.finalizedLatitude,
    this.finalizedLongitude,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      name: json['name'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      finalizedLatitude: json['finalized_latitude'] != null
          ? double.tryParse(json['finalized_latitude'].toString())
          : null,
      finalizedLongitude: json['finalized_longitude'] != null
          ? double.tryParse(json['finalized_longitude'].toString())
          : null,
    );
  }
}
