enum UserRole { admin, student }

class User {
  final String username;
  final String passwordHash;
  final UserRole role;
  final String? studentId;
  final String? name;
  final String? photoUrl;
  final String? contact;

  User({
    required this.username,
    required this.passwordHash,
    required this.role,
    this.studentId,
    this.name,
    this.photoUrl,
    this.contact,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] ?? '',
      passwordHash: json['passwordHash'] ?? '',
      role: json['role'] == 'admin' ? UserRole.admin : UserRole.student,
      studentId: json['studentId'],
      name: json['name'],
      photoUrl: json['photoUrl'],
      contact: json['contact'],
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'passwordHash': passwordHash,
        'role': role == UserRole.admin ? 'admin' : 'student',
        'studentId': studentId,
        'name': name,
        'photoUrl': photoUrl,
        'contact': contact,
      };

  User copyWith({
    String? photoUrl,
    String? name,
    String? contact,
  }) {
    return User(
      username: username,
      passwordHash: passwordHash,
      role: role,
      studentId: studentId,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      contact: contact ?? this.contact,
    );
  }
}
