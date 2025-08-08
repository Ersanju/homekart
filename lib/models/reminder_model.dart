class Reminder {
  final String id;
  final String? userId;
  final String name;
  final String relation;
  final String occasion;
  final DateTime date;

  Reminder({
    required this.id,
    this.userId,
    required this.name,
    required this.relation,
    required this.occasion,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'relation': relation,
      'occasion': occasion,
      'date': date.toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory Reminder.fromMap(String id, Map<String, dynamic> map) {
    return Reminder(
      id: id,
      userId: map['userId'],
      name: map['name'] ?? '',
      relation: map['relation'] ?? '',
      occasion: map['occasion'] ?? '',
      date: DateTime.parse(map['date']),
    );
  }
}
