
enum UserRole { admin, student }

class User {
  String username;
  String passwordHash;
  UserRole role;
  String? studentId; // for student role
  String? name;
  String? photoUrl;
  String? contact;

  User({
    required this.username,
    required this.passwordHash,
    required this.role,
    this.studentId,
    this.name,
    this.photoUrl,
    this.contact,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'passwordHash': passwordHash,
        'role': role == UserRole.admin ? 'admin' : 'student',
        'studentId': studentId,
        'name': name,
        'photoUrl': photoUrl,
        'contact': contact,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        username: json['username'],
        passwordHash: json['passwordHash'],
        role: json['role'] == 'admin' ? UserRole.admin : UserRole.student,
        studentId: json['studentId'],
        name: json['name'],
        photoUrl: json['photoUrl'],
        contact: json['contact'],
      );
}