import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/hostel.dart';
import '../models/student.dart';
import '../models/issue.dart';
import '../models/application.dart';
import '../models/user.dart';
import '../models/announcement.dart';

export '../models/user.dart';

class AuthResult {
  final UserRole role;
  final Student? student;
  final User? admin;

  AuthResult({required this.role, this.student, this.admin});
}

class AuthService {
  static String get baseUrl => apiUrl;

  List<Hostel> hostels = [];
  List<Student> students = [];
  List<Issue> issues = [];
  List<AccommodationApplication> applications = [];
  bool applicationsOpen = true;
  String? lastError;

  Future<void> loadData() async {
    try {
      final hostelsResponse = await http.get(Uri.parse('$baseUrl/hostels'));
      if (hostelsResponse.statusCode == 200) {
        final hostelsData = jsonDecode(hostelsResponse.body) as List<dynamic>;
        hostels = hostelsData.map((h) => Hostel.fromJson(h)).toList();
      }

      final studentsResponse = await http.get(Uri.parse('$baseUrl/students'));
      if (studentsResponse.statusCode == 200) {
        final studentsData = jsonDecode(studentsResponse.body) as List<dynamic>;
        students = studentsData.map((s) => Student.fromJson(s)).toList();
      }

      final issuesResponse = await http.get(Uri.parse('$baseUrl/issues'));
      if (issuesResponse.statusCode == 200) {
        final issuesData = jsonDecode(issuesResponse.body) as List<dynamic>;
        issues = issuesData.map((i) => Issue.fromJson(i)).toList();
      }

      final applicationsResponse =
          await http.get(Uri.parse('$baseUrl/applications'));
      if (applicationsResponse.statusCode == 200) {
        final applicationsData =
            jsonDecode(applicationsResponse.body) as List<dynamic>;
        applications = applicationsData
            .map((a) => AccommodationApplication.fromJson(a))
            .toList();
      }

      final settingsResponse = await http.get(Uri.parse('$baseUrl/settings'));
      if (settingsResponse.statusCode == 200) {
        final settings =
            jsonDecode(settingsResponse.body) as Map<String, dynamic>;
        applicationsOpen = settings['applicationsOpen'] ?? true;
      }
    } catch (_) {}
  }

  Future<AuthResult?> login({
    required UserRole role,
    required String username,
    required String password,
  }) async {
    lastError = null;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'role': role == UserRole.admin ? 'admin' : 'student',
          'username': username,
          'password': password.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (data['role'] == 'admin') {
            final adminUser = User.fromJson(data['user']);
            return AuthResult(role: UserRole.admin, admin: adminUser);
          } else if (data['role'] == 'student' && data['student'] != null) {
            final student = Student.fromJson(data['student']);
            return AuthResult(role: UserRole.student, student: student);
          }
        }
        lastError = data['message']?.toString() ?? 'Invalid credentials';
        return null;
      }

      try {
        final data = jsonDecode(response.body);
        lastError = data['message']?.toString() ??
            'Login failed (${response.statusCode})';
      } catch (_) {
        lastError = 'Login failed (${response.statusCode})';
      }
      return null;
    } catch (error) {
      lastError = error.toString();
      return null;
    }
  }

  Future<bool> register({
    required UserRole role,
    required String username,
    required String password,
    String? name,
    String? address,
    String? schoolEmail,
    String? schoolId,
  }) async {
    try {
      final payload = {
        'role': role == UserRole.admin ? 'admin' : 'student',
        'username': username,
        'password': password,
      };
      if (name != null) payload['name'] = name;
      if (address != null) payload['address'] = address;
      if (schoolEmail != null) payload['schoolEmail'] = schoolEmail;
      if (schoolId != null) payload['schoolId'] = schoolId;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String?> forgotPassword({
    required UserRole role,
    required String username,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'role': role == UserRole.admin ? 'admin' : 'student',
          'username': username,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['message'];
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> enrollStudentToRoom({
    required String studentId,
    required String blockId,
    required String roomNumber,
    DateTime? checkIn,
    DateTime? checkOut,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/enroll'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'studentId': studentId,
          'blockId': blockId,
          'roomNumber': roomNumber,
          'checkIn': checkIn?.toIso8601String(),
          'checkOut': checkOut?.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          await loadData();
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> autoAllocateStudent(String studentId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/enroll/auto'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'studentId': studentId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          await loadData();
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> submitAccommodationApplication(
      AccommodationApplication application) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/applications'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(application.toJson()),
      );

      if (response.statusCode == 200) {
        await loadData();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> submitIssue(Issue issue) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/issues'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(issue.toJson()),
      );

      if (response.statusCode == 200) {
        await loadData();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateApplicationStatus(String id, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/applications/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        await loadData();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateIssueStatus(String id, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/issues/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        await loadData();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  List<Student> searchStudents(String query) {
    final q = query.toLowerCase();
    return students.where((s) {
      return s.id.toLowerCase().contains(q) ||
          s.name.toLowerCase().contains(q) ||
          s.schoolEmail.toLowerCase().contains(q);
    }).toList();
  }

  bool canSubmitApplicationFor(String studentId) {
    if (!applicationsOpen) return false;
    if (!hostels.any((h) => h.availableSpots > 0)) return false;
    Student? student;
    for (final s in students) {
      if (s.id == studentId) {
        student = s;
        break;
      }
    }
    if (student == null) return false;
    if (student.isBlacklisted) return false;
    if (student.warningCount >= 3) return false;
    if (applications.any((a) => a.studentId == studentId)) return false;
    return true;
  }

  bool canSubmitApplication() =>
      applicationsOpen && hostels.any((h) => h.availableSpots > 0);

  Future<bool> acceptApplication(String studentId) async {
    final app = applications.firstWhere(
      (a) => a.studentId == studentId && a.status.toLowerCase() == 'pending',
      orElse: () => AccommodationApplication(
        id: '',
        studentId: '',
        hostelPreference: '',
        submissionDate: DateTime.now(),
      ),
    );
    if (app.id.isEmpty) return false;
    return updateApplicationStatus(app.id, 'approved');
  }

  Future<bool> rejectApplication(String studentId) async {
    final app = applications.firstWhere(
      (a) => a.studentId == studentId && a.status.toLowerCase() == 'pending',
      orElse: () => AccommodationApplication(
        id: '',
        studentId: '',
        hostelPreference: '',
        submissionDate: DateTime.now(),
      ),
    );
    if (app.id.isEmpty) return false;
    return updateApplicationStatus(app.id, 'rejected');
  }

  Future<bool> addHostel({
    required String id,
    required String name,
    required String gender,
    required String warden,
    required int rooms,
    required int capacity,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/hostels'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          'name': name,
          'gender': gender,
          'warden': warden,
          'rooms': List.generate(
            rooms,
            (index) => {
              'number': '$id-${(index + 1).toString().padLeft(3, '0')}',
              'capacity': capacity,
              'occupantIds': <String>[],
            },
          ),
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadData();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateStudent(Student student) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/students/${student.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(student.toJson()),
      );
      if (response.statusCode == 200) {
        await loadData();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setApplicationsOpen(bool isOpen) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/settings/applications'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'applicationsOpen': isOpen}),
      );
      if (response.statusCode == 200) {
        await loadData();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setStudentBlacklist(String studentId, bool isBlacklisted) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/students/$studentId/blacklist'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isBlacklisted': isBlacklisted}),
      );
      if (response.statusCode == 200) {
        await loadData();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addStudentWarning(String studentId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/students/$studentId/warnings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'delta': 1}),
      );
      if (response.statusCode == 200) {
        await loadData();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> changePassword({
    required UserRole role,
    required String username,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'role': role == UserRole.admin ? 'admin' : 'student',
          'username': username,
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateAdminProfile(User user) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/${user.username}/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      );
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<List<User>> getAdmins() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/users'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data.map((u) => User.fromJson(u)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> addAdmin(User admin) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(admin.toJson()),
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<List<Announcement>> getAnnouncements() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/announcements'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data.map((a) => Announcement.fromJson(a)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> addAnnouncement(Announcement ann) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/announcements'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(ann.toJson()),
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (_) {}
    return false;
  }
}
