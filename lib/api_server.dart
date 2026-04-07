import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'dart:convert';
import 'storage/data_storage.dart';
import 'models/student.dart';
import 'models/hostel.dart';
import 'models/user.dart';
import 'models/announcement.dart';

class ApiServer {
  late Router _router;

  ApiServer() {
    _router = Router();
    _setupRoutes();
  }

  void _setupRoutes() {
    // Authentication
    _router.post('/auth/login', _handleLogin);
    _router.post('/auth/register', _handleRegister);
    _router.post('/auth/forgot-password', _handleForgotPassword);
    _router.post('/auth/change-password', _handleChangePassword);

    // Profile updates
    _router.put('/students/<id>/profile', _handleUpdateStudentProfile);
    _router.put('/users/<username>/profile', _handleUpdateAdminProfile);

    // Admin Users
    _router.get('/admin/users', _handleGetAdmins);
    _router.post('/admin/users', _handleAddAdmin);

    // Announcements
    _router.get('/announcements', _handleGetAnnouncements);
    _router.post('/announcements', _handleAddAnnouncement);

    // Students
    _router.get('/students', _handleGetStudents);
    _router.post('/students', _handleAddStudent);
    _router.put('/students/<id>', _handleUpdateStudent);
    _router.put('/students/<id>/warnings', _handleUpdateStudentWarnings);
    _router.put('/students/<id>/blacklist', _handleUpdateStudentBlacklist);

    // Hostels
    _router.get('/hostels', _handleGetHostels);
    _router.post('/hostels', _handleAddHostel);

    // Enrollment
    _router.post('/enroll', _handleEnroll);
    _router.post('/enroll/auto', _handleAutoEnroll);

    // Applications
    _router.get('/applications', _handleGetApplications);
    _router.post('/applications', _handleAddApplication);
    _router.put('/applications/<id>/status', _handleUpdateApplicationStatus);

    // Issues
    _router.get('/issues', _handleGetIssues);
    _router.post('/issues', _handleAddIssue);
    _router.put('/issues/<id>/status', _handleUpdateIssueStatus);

    // Admin settings
    _router.get('/settings', _handleGetSettings);
    _router.put('/settings/applications', _handleUpdateApplicationsState);
  }

  bool _isFemale(String gender) => gender.trim().toLowerCase().startsWith('f');

  bool _isMale(String gender) => gender.trim().toLowerCase().startsWith('m');

  bool _isGirlsBlock(String hostelId) {
    if (hostelId.isEmpty) return false;
    final c = hostelId.trim().toUpperCase().codeUnitAt(0);
    return c >= 'A'.codeUnitAt(0) && c <= 'H'.codeUnitAt(0);
  }

  bool _isBoysBlock(String hostelId) {
    if (hostelId.isEmpty) return false;
    final c = hostelId.trim().toUpperCase().codeUnitAt(0);
    return c >= 'I'.codeUnitAt(0) && c <= 'L'.codeUnitAt(0);
  }

  Future<Response> _handleLogin(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final role = data['role'];
      final username = (data['username'] ?? '').toString().trim();
      final password = (data['password'] ?? '').toString();
      final normalizedUsername = username.toLowerCase();
      final trimmedPassword = password.trim();

      if (role == 'admin') {
        final user = DataStorage.users.firstWhere(
          (u) => u.username.toLowerCase() == normalizedUsername && u.role == UserRole.admin,
          orElse: () => User(username: '', passwordHash: '', role: UserRole.admin),
        );
        
        if (user.username.isNotEmpty) {
          // Compare passwords (trim both for consistency)
          final storedPasswordTrimmed = user.passwordHash.trim();
          final adminPasswordMatches = storedPasswordTrimmed == password || storedPasswordTrimmed == trimmedPassword;
          
          if (adminPasswordMatches) {
            return Response.ok(
              jsonEncode({'success': true, 'role': 'admin', 'user': user.toJson()}),
              headers: {'Content-Type': 'application/json'},
            );
          }
        }
      } else if (role == 'student') {
        for (var student in DataStorage.students) {
          final matchesStudent = student.id.toLowerCase() == normalizedUsername ||
              student.schoolId.toLowerCase() == normalizedUsername ||
              student.schoolEmail.toLowerCase() == normalizedUsername;
          
          // Compare passwords (trim both for consistency)
          final storedPasswordTrimmed = student.password.trim();
          final studentPasswordMatches =
              storedPasswordTrimmed == password || storedPasswordTrimmed == trimmedPassword;
          
          if (matchesStudent && studentPasswordMatches) {
            return Response.ok(
              jsonEncode({
                'success': true,
                'role': 'student',
                'student': student.toJson(),
              }),
              headers: {'Content-Type': 'application/json'},
            );
          }
        }
      }

      return Response.unauthorized(
        jsonEncode({'success': false, 'message': 'Invalid credentials'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _handleRegister(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final username = (data['username'] ?? '').toString().trim();
      final password = data['password'];
      final role = data['role'];

      if (role == 'student') {
        final normalized = username.toLowerCase();
        final exists = DataStorage.students.any(
          (s) =>
              s.id.toLowerCase() == normalized ||
              s.schoolId.toLowerCase() == normalized ||
              s.schoolEmail.toLowerCase() == normalized,
        );
        if (exists) {
          return Response.badRequest(
            body: jsonEncode({'success': false, 'message': 'Student account already exists'}),
            headers: {'Content-Type': 'application/json'},
          );
        }

        final generatedId = username.contains('@')
            ? 'S${DateTime.now().millisecondsSinceEpoch}'
            : username.toUpperCase();
        final newStudent = Student(
          id: generatedId,
          name: username.contains('@') ? username.split('@').first : username,
          password: password,
          schoolEmail: username.contains('@') ? username.toLowerCase() : '${username.toLowerCase()}@africau.edu',
          schoolId: generatedId,
          degree: '',
          gender: '',
          medicalAid: '',
          specialConditions: '',
          hostelName: '',
          roomNumber: '',
          contact: '',
          roommateNames: [],
        );
        DataStorage.students.add(newStudent);
        await DataStorage.saveStudents();
        return Response.ok(
          jsonEncode({'success': true, 'message': 'New account created successfully'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.badRequest(
        body: jsonEncode({'success': false, 'message': 'Invalid role'}),
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _handleForgotPassword(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final username = data['username'];
      final role = data['role'];
      final newPassword = (data['newPassword'] ?? '').toString();

      if (newPassword.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'success': false, 'message': 'New password is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (role == 'student') {
        final normalized = (username ?? '').toString().trim().toLowerCase();
        final student = DataStorage.students.firstWhere(
          (s) =>
              s.id.toLowerCase() == normalized ||
              s.schoolId.toLowerCase() == normalized ||
              s.schoolEmail.toLowerCase() == normalized,
          orElse: () => Student(
            id: '',
            name: '',
            password: '',
            schoolEmail: '',
            schoolId: '',
            degree: '',
            gender: '',
            medicalAid: '',
            specialConditions: '',
            hostelName: '',
            roomNumber: '',
            contact: '',
            roommateNames: [],
          ),
        );
        if (student.id.isNotEmpty) {
          student.password = newPassword;
          await DataStorage.saveStudents();
          return Response.ok(
            jsonEncode({'success': true, 'message': 'Password updated successfully'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      } else if (role == 'admin') {
        final normalized = (username ?? '').toString().trim().toLowerCase();
        final user = DataStorage.users.firstWhere(
          (u) => u.username.toLowerCase() == normalized && u.role == UserRole.admin,
          orElse: () => User(username: '', passwordHash: '', role: UserRole.admin),
        );
        if (user.username.isNotEmpty) {
          user.passwordHash = newPassword;
          await DataStorage.saveUsers();
          return Response.ok(
            jsonEncode({'success': true, 'message': 'Password updated successfully'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      }

      return Response.badRequest(
        body: jsonEncode({'success': false, 'message': 'User not found'}),
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _handleGetStudents(Request request) async {
    return Response.ok(
      jsonEncode(DataStorage.students.map((s) => s.toJson()).toList()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _handleAddStudent(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final student = Student.fromJson(data);
      DataStorage.students.add(student);
      await DataStorage.saveStudents();

      return Response.ok(
        jsonEncode(student.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _handleGetHostels(Request request) async {
    return Response.ok(
      jsonEncode(DataStorage.hostels.map((h) => h.toJson()).toList()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _handleAddHostel(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final hostel = Hostel.fromJson(data);
      DataStorage.hostels.add(hostel);
      await DataStorage.saveHostels();

      return Response.ok(
        jsonEncode(hostel.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _handleEnroll(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final studentId = (data['studentId'] ?? '').toString().trim().toLowerCase();
      final blockId = (data['blockId'] ?? '').toString().trim().toUpperCase();
      final roomNumber = (data['roomNumber'] ?? '').toString().trim().toUpperCase();

      final student = DataStorage.students.firstWhere(
        (s) => s.id.toLowerCase() == studentId,
        orElse: () => throw Exception('Student not found'),
      );

      final hostel = DataStorage.hostels.firstWhere(
        (h) => h.id.toUpperCase() == blockId,
        orElse: () => throw Exception('Hostel not found'),
      );

      final room = hostel.rooms.firstWhere(
        (r) => r.number.toUpperCase() == roomNumber,
        orElse: () => throw Exception('Room not found'),
      );

      final gender = student.gender.trim();
      if (gender.isEmpty) {
        return Response(
          400,
          body: jsonEncode({'success': false, 'message': 'Student gender is required for allocation'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      if (_isFemale(gender) && !_isGirlsBlock(hostel.id)) {
        return Response(
          400,
          body: jsonEncode({'success': false, 'message': 'Female students can only be allocated to A-H'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      if (_isMale(gender) && !_isBoysBlock(hostel.id)) {
        return Response(
          400,
          body: jsonEncode({'success': false, 'message': 'Male students can only be allocated to I-L'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!room.isAvailable) {
        return Response(400,
            body: jsonEncode({'success': false, 'message': 'Room is full'}));
      }

      room.occupantIds.add(student.id);
      student.hostelName = hostel.name;
      student.roomNumber = room.number;

      await DataStorage.saveHostels();
      await DataStorage.saveStudents();

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _handleAutoEnroll(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final studentId = (data['studentId'] ?? '').toString().trim().toLowerCase();

      final student = DataStorage.students.firstWhere(
        (s) => s.id.toLowerCase() == studentId,
        orElse: () => throw Exception('Student not found'),
      );

      if (student.roomNumber.isNotEmpty) {
        return Response.ok(
          jsonEncode({
            'success': true,
            'message': 'Student already allocated',
            'hostel': student.hostelName,
            'room': student.roomNumber,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final studentGender = student.gender.trim();
      if (studentGender.isEmpty) {
        return Response(
          400,
          body: jsonEncode({'success': false, 'message': 'Student gender is required for allocation'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      final shouldAllocateGirls = _isFemale(studentGender);

      for (final hostel in DataStorage.hostels) {
        final allowedBlock = shouldAllocateGirls ? _isGirlsBlock(hostel.id) : _isBoysBlock(hostel.id);
        if (!allowedBlock) {
          continue;
        }
        for (final room in hostel.rooms) {
          if (room.isAvailable) {
            room.occupantIds.add(student.id);
            student.hostelName = hostel.name;
            student.roomNumber = room.number;

            await DataStorage.saveHostels();
            await DataStorage.saveStudents();

            return Response.ok(
              jsonEncode({
                'success': true,
                'hostel': hostel.name,
                'room': room.number,
                'message': 'Student auto-allocated successfully',
              }),
              headers: {'Content-Type': 'application/json'},
            );
          }
        }
      }

      return Response(
        409,
        body: jsonEncode({
          'success': false,
          'message': shouldAllocateGirls
              ? 'No free rooms available in A-H female hostels'
              : 'No free rooms available in I-L male hostels',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _handleGetApplications(Request request) async {
    return Response.ok(
      jsonEncode(
        DataStorage.applications.map((a) => a.toJson()).toList(),
      ),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _handleAddApplication(Request request) async {
    try {
      if (!DataStorage.applicationsOpen) {
        return Response.forbidden(
          jsonEncode({'success': false, 'message': 'Applications are currently closed'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = await request.readAsString();
      final data = jsonDecode(body);
      final application = AccommodationApplication.fromJson(data);

      final student = DataStorage.students.firstWhere(
        (s) => s.id == application.studentId,
        orElse: () => throw Exception('Student not found'),
      );

      if (student.isBlacklisted) {
        return Response.forbidden(
          jsonEncode({'success': false, 'message': 'You are blacklisted from applying'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (student.warningCount >= 3) {
        return Response.forbidden(
          jsonEncode({
            'success': false,
            'message': 'You have 3 warnings and cannot apply this semester',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final hasSubmittedBefore = DataStorage.applications.any(
        (a) => a.studentId == application.studentId,
      );
      if (hasSubmittedBefore) {
        return Response(
          409,
          body: jsonEncode({
            'success': false,
            'message': 'Student can only apply once for accommodation',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final special = student.specialConditions.toLowerCase();
      if (special.contains('disabled') || special.contains('disability')) {
        application.status = 'approved';
      }

      DataStorage.applications.add(application);
      await DataStorage.saveApplications();

      return Response.ok(
        jsonEncode(application.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _handleUpdateApplicationStatus(
    Request request,
    String id,
  ) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final status = data['status'];

      final application = DataStorage.applications.firstWhere(
        (a) => a.id == id,
        orElse: () => throw Exception('Application not found'),
      );

      application.status = status;
      await DataStorage.saveApplications();

      return Response.ok(
        jsonEncode(application.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _handleGetIssues(Request request) async {
    return Response.ok(
      jsonEncode(DataStorage.issues.map((i) => i.toJson()).toList()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _handleAddIssue(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final issue = Issue.fromJson(data);
      DataStorage.issues.add(issue);
      await DataStorage.saveIssues();

      return Response.ok(
        jsonEncode(issue.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _handleUpdateIssueStatus(
    Request request,
    String id,
  ) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final status = data['status'];

      final issue = DataStorage.issues.firstWhere(
        (i) => i.id == id,
        orElse: () => throw Exception('Issue not found'),
      );

      issue.status = status;
      await DataStorage.saveIssues();

      return Response.ok(
        jsonEncode(issue.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _handleUpdateStudent(Request request, String id) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final updated = Student.fromJson(data);
      final index = DataStorage.students.indexWhere((s) => s.id == id);
      if (index == -1) {
        return Response.notFound(jsonEncode({'error': 'Student not found'}));
      }
      DataStorage.students[index] = updated;
      await DataStorage.saveStudents();
      return Response.ok(
        jsonEncode(updated.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _handleUpdateStudentWarnings(Request request, String id) async {
    try {
      final student = DataStorage.students.firstWhere(
        (s) => s.id == id,
        orElse: () => throw Exception('Student not found'),
      );
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final delta = data['delta'] ?? 1;
      student.warningCount = (student.warningCount + delta).clamp(0, 10).toInt();
      await DataStorage.saveStudents();
      return Response.ok(
        jsonEncode(student.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _handleUpdateStudentBlacklist(Request request, String id) async {
    try {
      final student = DataStorage.students.firstWhere(
        (s) => s.id == id,
        orElse: () => throw Exception('Student not found'),
      );
      final body = await request.readAsString();
      final data = jsonDecode(body);
      student.isBlacklisted = data['isBlacklisted'] ?? false;
      await DataStorage.saveStudents();
      return Response.ok(
        jsonEncode(student.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _handleGetSettings(Request request) async {
    return Response.ok(
      jsonEncode({'applicationsOpen': DataStorage.applicationsOpen}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _handleUpdateApplicationsState(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      DataStorage.applicationsOpen = data['applicationsOpen'] ?? true;
      await DataStorage.savePolicies();
      return Response.ok(
        jsonEncode({'applicationsOpen': DataStorage.applicationsOpen}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _handleChangePassword(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final role = data['role'];
      final username = (data['username'] ?? '').toString().trim();
      final normalizedUsername = username.toLowerCase();
      final oldPassword = (data['oldPassword'] ?? '').toString();
      final newPassword = (data['newPassword'] ?? '').toString();

      if (role == 'admin') {
        final user = DataStorage.users.firstWhere(
          (u) => u.username.toLowerCase() == normalizedUsername && u.role == UserRole.admin,
        );
        if (user.passwordHash == oldPassword) {
          user.passwordHash = newPassword;
          await DataStorage.saveUsers();
          return Response.ok(jsonEncode({'success': true}));
        }
      } else if (role == 'student') {
        final student = DataStorage.students.firstWhere(
          (s) =>
              s.id.toLowerCase() == normalizedUsername ||
              s.schoolId.toLowerCase() == normalizedUsername ||
              s.schoolEmail.toLowerCase() == normalizedUsername,
        );
        if (student.password == oldPassword) {
          student.password = newPassword;
          await DataStorage.saveStudents();
          return Response.ok(jsonEncode({'success': true}));
        }
      }
      return Response.forbidden(jsonEncode({'success': false, 'message': 'Invalid old password'}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> _handleUpdateStudentProfile(Request request, String id) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final student = DataStorage.students.firstWhere((s) => s.id == id);
      if (data.containsKey('photoUrl')) student.photoUrl = data['photoUrl'];
      if (data.containsKey('contact')) student.contact = data['contact'];
      await DataStorage.saveStudents();
      return Response.ok(jsonEncode(student.toJson()), headers: {'Content-Type': 'application/json'});
    } catch(e) { return Response.internalServerError(body: jsonEncode({'error': e.toString()})); }
  }

  Future<Response> _handleUpdateAdminProfile(Request request, String username) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final user = DataStorage.users.firstWhere((u) => u.username == username && u.role == UserRole.admin);
      if (data.containsKey('photoUrl')) user.photoUrl = data['photoUrl'];
      if (data.containsKey('name')) user.name = data['name'];
      if (data.containsKey('contact')) user.contact = data['contact'];
      await DataStorage.saveUsers();
      return Response.ok(jsonEncode(user.toJson()), headers: {'Content-Type': 'application/json'});
    } catch(e) { return Response.internalServerError(body: jsonEncode({'error': e.toString()})); }
  }

  Future<Response> _handleGetAdmins(Request request) async {
    final admins = DataStorage.users.where((u) => u.role == UserRole.admin).map((u) => u.toJson()).toList();
    return Response.ok(jsonEncode(admins), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _handleAddAdmin(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      data['role'] = 'admin'; // ensure role is set
      final user = User.fromJson(data);
      if (DataStorage.users.any((u) => u.username == user.username)) {
         return Response.badRequest(body: jsonEncode({'success': false, 'message': 'Admin username already exists'}));
      }
      DataStorage.users.add(user);
      await DataStorage.saveUsers();
      return Response.ok(jsonEncode(user.toJson()), headers: {'Content-Type': 'application/json'});
    } catch(e) { return Response.internalServerError(body: jsonEncode({'error': e.toString()})); }
  }

  Future<Response> _handleGetAnnouncements(Request request) async {
    return Response.ok(jsonEncode(DataStorage.announcements.map((a) => a.toJson()).toList()), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _handleAddAnnouncement(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final ann = Announcement.fromJson(data);
      if (ann.id.isEmpty) { ann.id = DateTime.now().millisecondsSinceEpoch.toString(); }
      DataStorage.announcements.add(ann);
      await DataStorage.saveAnnouncements();
      return Response.ok(jsonEncode(ann.toJson()), headers: {'Content-Type': 'application/json'});
    } catch(e) { return Response.internalServerError(body: jsonEncode({'error': e.toString()})); }
  }

  Future<void> startServer() async {
    await DataStorage.initializeData();

    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_corsMiddleware)
        .addHandler(_router.call);

    final server = await io.serve(handler, '0.0.0.0', 8080);
    print('Server running on http://${server.address.host}:${server.port}');
  }

  Middleware _corsMiddleware = (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok(null, headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type',
        });
      }
      final response = await innerHandler(request);
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      });
    };
  };
}

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'hostelPreference': hostelPreference,
        'status': status,
        'submissionDate': submissionDate.toIso8601String(),
      };

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
}

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'hostelId': hostelId,
        'description': description,
        'status': status,
        'reportDate': reportDate.toIso8601String(),
      };

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
}
