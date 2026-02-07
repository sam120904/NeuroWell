class Patient {
  final String id;
  final String name;
  final String email;
  final DateTime dateAdded;
  final String status; // 'Active', 'Inactive'
  final String avatarUrl; // Placeholder

  Patient({
    required this.id,
    required this.name,
    required this.email,
    required this.dateAdded,
    required this.status,
    this.avatarUrl = '',
  });
}
