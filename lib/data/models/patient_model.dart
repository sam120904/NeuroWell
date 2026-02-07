class Patient {
  final String id;
  final String name;
  final String email;
  final int age;
  final String condition;
  final String contactNumber;
  final DateTime dateAdded;
  final String status; // 'Active', 'Inactive'
  final String avatarUrl; // Placeholder

  Patient({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.condition,
    required this.contactNumber,
    required this.dateAdded,
    required this.status,
    this.avatarUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'age': age,
      'condition': condition,
      'contactNumber': contactNumber,
      'dateAdded': dateAdded.millisecondsSinceEpoch,
      'status': status,
      'avatarUrl': avatarUrl,
    };
  }

  factory Patient.fromMap(String id, Map<String, dynamic> map) {
    return Patient(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      age: map['age'] ?? 0,
      condition: map['condition'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      dateAdded: map['dateAdded'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dateAdded']) 
          : DateTime.now(),
      status: map['status'] ?? 'Active',
      avatarUrl: map['avatarUrl'] ?? '',
    );
  }
}
