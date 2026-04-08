class Student {
  final String id;
  final String name;
  final String password;
  final String schoolEmail;
  final String schoolId;
  final String degree;
  final String gender;
  final String medicalAid;
  final String specialConditions;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String hostelName;
  final String roomNumber;
  final String contact;
  final String address;
  final List<String> roommateNames;
  final bool isBlacklisted;
  final int warningCount;
  final String? photoUrl;
  final bool isRegistered;

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
    required this.address,
    required this.roommateNames,
    this.isBlacklisted = false,
    this.warningCount = 0,
    this.photoUrl,
    this.isRegistered = false,
  });

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
      checkOut:
          json['checkOut'] != null ? DateTime.parse(json['checkOut']) : null,
      hostelName: json['hostelName'] ?? '',
      roomNumber: json['roomNumber'] ?? '',
      contact: json['contact'] ?? '',
      address: json['address'] ?? '',
      roommateNames: List<String>.from(json['roommateNames'] ?? []),
      isBlacklisted: json['isBlacklisted'] ?? false,
      warningCount: json['warningCount'] ?? 0,
      photoUrl: json['photoUrl'],
      isRegistered: json['isRegistered'] ?? false,
    );
  }

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
        'address': address,
      };

  Student copyWith({
    String? schoolEmail,
    String? schoolId,
    String? degree,
    String? gender,
    String? medicalAid,
    String? specialConditions,
    bool? isBlacklisted,
    int? warningCount,
    String? photoUrl,
    String? contact,
    String? address,
  }) {
    return Student(
      id: id,
      name: name,
      password: password,
      schoolEmail: schoolEmail ?? this.schoolEmail,
      schoolId: schoolId ?? this.schoolId,
      degree: degree ?? this.degree,
      gender: gender ?? this.gender,
      medicalAid: medicalAid ?? this.medicalAid,
      specialConditions: specialConditions ?? this.specialConditions,
      checkIn: checkIn,
      checkOut: checkOut,
      hostelName: hostelName,
      roomNumber: roomNumber,
      contact: contact ?? this.contact,
      address: address ?? this.address,
      roommateNames: roommateNames,
      isBlacklisted: isBlacklisted ?? this.isBlacklisted,
      warningCount: warningCount ?? this.warningCount,
      photoUrl: photoUrl ?? this.photoUrl,
      isRegistered: isRegistered,
    );
  }
}
