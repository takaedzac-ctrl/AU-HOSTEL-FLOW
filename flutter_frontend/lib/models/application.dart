class AccommodationApplication {
  String id;
  String studentId;
  String hostelPreference;
  String status;
  DateTime submissionDate;

  AccommodationApplication({
    required this.id,
    required this.studentId,
    required this.hostelPreference,
    this.status = 'pending',
    required this.submissionDate,
  });

  factory AccommodationApplication.fromJson(Map<String, dynamic> json) {
    return AccommodationApplication(
      id: json['id'] ?? '',
      studentId: json['studentId'] ?? '',
      hostelPreference: json['hostelPreference'] ?? '',
      status: json['status'] ?? 'pending',
      submissionDate: json['submissionDate'] != null
          ? DateTime.parse(json['submissionDate'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'hostelPreference': hostelPreference,
        'status': status,
        'submissionDate': submissionDate.toIso8601String(),
      };
}
