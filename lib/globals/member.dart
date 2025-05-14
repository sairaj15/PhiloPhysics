class Member {
  final String name;
  final String role;

  Member({required this.name, required this.role});

  factory Member.fromMap(Map<dynamic, dynamic> map) {
    return Member(
      name: map['name'] ?? '',
      role: map['role'] ?? '',
    );
  }
}
