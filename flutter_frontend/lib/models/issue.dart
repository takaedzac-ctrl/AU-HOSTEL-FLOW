class Issue {
  String id;
  String studentId;
  String hostelId;
  String description;
  String status;
  DateTime reportDate;

  Issue({
    required this.id,
    required this.studentId,
    required this.hostelId,
    required this.description,
    this.status = 'open',
    required this.reportDate,
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id'] ?? '',
      studentId: json['studentId'] ?? '',
      hostelId: json['hostelId'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'open',
      reportDate: json['reportDate'] != null
          ? DateTime.parse(json['reportDate'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'hostelId': hostelId,
        'description': description,
        'status': status,
        'reportDate': reportDate.toIso8601String(),
      };
}
