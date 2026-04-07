class Student {
  String id;
  String name;
  String password;
  String schoolEmail;
  String schoolId;
  String degree;
  String gender;
  String medicalAid;
  String specialConditions;
  DateTime? checkIn;
  DateTime? checkOut;
  String hostelName;
  String roomNumber;
  String contact;
  List<String> roommateNames;
  bool isBlacklisted;
  int warningCount;
  String? photoUrl;
  bool isRegistered;

  Student({
    required this.id,
    required this.name,
    required this.password,
    required this.schoolEmail,
    required this.schoolId,
    required this.degree,
    required this.gender,
    required this.medicalAid,
    required this.specialConditions,
    this.checkIn,
    this.checkOut,
    required this.hostelName,
    required this.roomNumber,
    required this.contact,
    required this.roommateNames,
    this.isBlacklisted = false,
    this.warningCount = 0,
    this.photoUrl,
    this.isRegistered = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'password': password,
        'schoolEmail': schoolEmail,
        'schoolId': schoolId,
        'degree': degree,
        'gender': gender,
        'medicalAid': medicalAid,
        'specialConditions': specialConditions,
        'checkIn': checkIn?.toIso8601String(),
        'checkOut': checkOut?.toIso8601String(),
        'hostelName': hostelName,
        'roomNumber': roomNumber,
        'contact': contact,
        'roommateNames': roommateNames,
        'isBlacklisted': isBlacklisted,
        'warningCount': warningCount,
        'photoUrl': photoUrl,
        'isRegistered': isRegistered,
      };

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      password: json['password'] ?? '',
      schoolEmail: json['schoolEmail'] ?? '',
      schoolId: json['schoolId'] ?? '',
      degree: json['degree'] ?? '',
      gender: json['gender'] ?? '',
      medicalAid: json['medicalAid'] ?? '',
      specialConditions: json['specialConditions'] ?? '',
      checkIn: json['checkIn'] != null ? DateTime.parse(json['checkIn']) : null,
      checkOut: json['checkOut'] != null ? DateTime.parse(json['checkOut']) : null,
      hostelName: json['hostelName'] ?? '',
      roomNumber: json['roomNumber'] ?? '',
      contact: json['contact'] ?? '',
      roommateNames: List<String>.from(json['roommateNames'] ?? []),
      isBlacklisted: json['isBlacklisted'] ?? false,
      warningCount: json['warningCount'] ?? 0,
      photoUrl: json['photoUrl'],
      isRegistered: json['isRegistered'] ?? false,
    );
  }
}