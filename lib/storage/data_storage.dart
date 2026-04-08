import 'dart:convert';
import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import '../models/student.dart';
import '../models/hostel.dart';
import '../models/room.dart';
import '../models/user.dart';
import '../models/announcement.dart';
import '../api_server.dart';

class DataStorage {
  static List<Student> students = [];
  static List<Hostel> hostels = [];
  static List<AccommodationApplication> applications = [];
  static List<Issue> issues = [];
  static List<User> users = [];
  static List<Announcement> announcements = [];
  static bool applicationsOpen = true;

  static Database? _db;
  static const String _dbFile = 'au_hostel_flow.db';

  static Future<void> initializeData() async {
    _initDatabase();
    await _bootstrapFromLegacyJsonIfNeeded();
    await loadStudents();
    await loadHostels();
    await loadApplications();
    await loadIssues();
    await loadAnnouncements();
    await loadUsers();
    await loadPolicies();

    if (students.isEmpty) {
      students = _defaultStudents();
      await saveStudents();
    }
    if (hostels.isEmpty) {
      _initializeDefaultHostels();
      await saveHostels();
    }
    if (users.isEmpty) {
      users.add(User(
        username: 'admin',
        passwordHash: _hashPassword('admin123'),
        role: UserRole.admin,
      ));
      await saveUsers();
    }
    final hasAdmin = users.any(
      (u) => u.role == UserRole.admin && u.username.toLowerCase() == 'admin',
    );
    if (!hasAdmin) {
      users.add(User(
        username: 'admin',
        passwordHash: _hashPassword('admin123'),
        role: UserRole.admin,
      ));
      await saveUsers();
    }
  }

  static void _initializeDefaultHostels() {
    const girlsBlocks = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    for (var block in girlsBlocks) {
      final roomCount = block == 'E' ? 74 : 21;
      hostels.add(Hostel(
        id: block,
        name: '$block block',
        gender: 'Girls',
        warden: 'Warden $block',
        rooms: List.generate(roomCount, (index) {
          final roomNo = '$block-${(index + 1).toString().padLeft(3, '0')}';
          return Room(number: roomNo, capacity: 2);
        }),
      ));
    }
    const boysBlocks = ['I', 'J', 'K', 'L'];
    for (var block in boysBlocks) {
      hostels.add(Hostel(
        id: block,
        name: '$block block',
        gender: 'Boys',
        warden: 'Warden $block',
        rooms: List.generate(37, (index) {
          final roomNo = '$block-${(index + 1).toString().padLeft(3, '0')}';
          return Room(number: roomNo, capacity: 3);
        }),
      ));
    }
  }

  static Future<void> saveStudents() async =>
      _saveCollection('students', students.map((e) => e.toJson()).toList());

  static Future<void> loadStudents() async {
    final data = _loadCollection('students');
    students = data.map<Student>((e) => Student.fromJson(e)).toList();
  }

  static Future<void> saveHostels() async =>
      _saveCollection('hostels', hostels.map((e) => e.toJson()).toList());

  static Future<void> loadHostels() async {
    final data = _loadCollection('hostels');
    hostels = data.map<Hostel>((e) => Hostel.fromJson(e)).toList();
  }

  static Future<void> saveApplications() async => _saveCollection(
        'applications',
        applications.map((e) => e.toJson()).toList(),
      );

  static Future<void> loadApplications() async {
    final data = _loadCollection('applications');
    applications = data
        .map<AccommodationApplication>(
            (e) => AccommodationApplication.fromJson(e))
        .toList();
  }

  static Future<void> saveIssues() async =>
      _saveCollection('issues', issues.map((e) => e.toJson()).toList());

  static Future<void> loadIssues() async {
    final data = _loadCollection('issues');
    issues = data.map<Issue>((e) => Issue.fromJson(e)).toList();
  }

  static Future<void> saveAnnouncements() async => _saveCollection(
        'announcements',
        announcements.map((e) => e.toJson()).toList(),
      );

  static Future<void> loadAnnouncements() async {
    final data = _loadCollection('announcements');
    announcements =
        data.map<Announcement>((e) => Announcement.fromJson(e)).toList();
  }

  static Future<void> savePolicies() async {
    _db!.execute(
      'INSERT INTO settings(key, value) VALUES(?, ?) ON CONFLICT(key) DO UPDATE SET value=excluded.value',
      ['applicationsOpen', applicationsOpen ? 'true' : 'false'],
    );
  }

  static Future<void> loadPolicies() async {
    final rs = _db!.select(
      'SELECT value FROM settings WHERE key = ? LIMIT 1',
      ['applicationsOpen'],
    );
    if (rs.isEmpty) {
      applicationsOpen = true;
      await savePolicies();
      return;
    }
    applicationsOpen = rs.first['value'] == 'true';
  }

  static Future<void> saveUsers() async =>
      _saveCollection('users', users.map((e) => e.toJson()).toList());

  static Future<void> loadUsers() async {
    final data = _loadCollection('users');
    users = data.map<User>((e) => User.fromJson(e)).toList();
  }

  static String _hashPassword(String password) {
    // Simple hash for demo, in production use proper hashing
    return password; // For now, no hash
  }

  static void autoAllocateRooms() {
    // Find students without rooms
    final unallocatedStudents =
        students.where((s) => s.roomNumber.isEmpty).toList();

    for (final student in unallocatedStudents) {
      // Find suitable hostels based on gender
      final suitableHostels = hostels
          .where((h) => h.gender == student.gender || h.gender == 'Mixed')
          .toList();

      for (final hostel in suitableHostels) {
        // Find available rooms
        final availableRoom = hostel.rooms.firstWhere(
          (r) => r.isAvailable,
          orElse: () => Room(number: '', capacity: 0),
        );
        if (availableRoom.number.isNotEmpty) {
          // Allocate the room
          student.hostelName = hostel.name;
          student.roomNumber = availableRoom.number;
          availableRoom.occupantIds.add(student.id);
          break; // Allocated, move to next student
        }
      }
    }

    // Save changes
    saveStudents();
    saveHostels();
  }

  static void _initDatabase() {
    _db ??= sqlite3.open(_dbFile);
    _db!.execute(
        'CREATE TABLE IF NOT EXISTS students (key TEXT PRIMARY KEY, data TEXT NOT NULL)');
    _db!.execute(
        'CREATE TABLE IF NOT EXISTS hostels (key TEXT PRIMARY KEY, data TEXT NOT NULL)');
    _db!.execute(
        'CREATE TABLE IF NOT EXISTS applications (key TEXT PRIMARY KEY, data TEXT NOT NULL)');
    _db!.execute(
        'CREATE TABLE IF NOT EXISTS issues (key TEXT PRIMARY KEY, data TEXT NOT NULL)');
    _db!.execute(
        'CREATE TABLE IF NOT EXISTS users (key TEXT PRIMARY KEY, data TEXT NOT NULL)');
    _db!.execute(
        'CREATE TABLE IF NOT EXISTS announcements (key TEXT PRIMARY KEY, data TEXT NOT NULL)');
    _db!.execute(
        'CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
  }

  static List<Map<String, dynamic>> _loadCollection(String table) {
    final rs = _db!.select('SELECT data FROM $table ORDER BY key');
    return rs
        .map((row) => jsonDecode(row['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  static Future<void> _saveCollection(
    String table,
    List<Map<String, dynamic>> items,
  ) async {
    _db!.execute('DELETE FROM $table');
    final stmt = _db!.prepare('INSERT INTO $table(key, data) VALUES(?, ?)');
    try {
      for (final item in items) {
        final key = (item['id'] ??
                item['username'] ??
                DateTime.now().microsecondsSinceEpoch)
            .toString();
        stmt.execute([key, jsonEncode(item)]);
      }
    } finally {
      stmt.dispose();
    }
  }

  static Future<void> _bootstrapFromLegacyJsonIfNeeded() async {
    final hasStudents =
        _db!.select('SELECT 1 FROM students LIMIT 1').isNotEmpty;
    if (hasStudents) return;

    await _importLegacyList('students.json', 'students');
    await _importLegacyList('hostels.json', 'hostels');
    await _importLegacyList('applications.json', 'applications');
    await _importLegacyList('issues.json', 'issues');
    await _importLegacyList('users.json', 'users');
    await _importLegacyList('announcements.json', 'announcements');

    final policies = File('policies.json');
    if (policies.existsSync()) {
      final data =
          jsonDecode(policies.readAsStringSync()) as Map<String, dynamic>;
      applicationsOpen = data['applicationsOpen'] ?? true;
      await savePolicies();
    }
  }

  static Future<void> _importLegacyList(String fileName, String table) async {
    final file = File(fileName);
    if (!file.existsSync()) return;
    final raw = file.readAsStringSync().trim();
    if (raw.isEmpty) return;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return;

    final stmt = _db!.prepare('INSERT INTO $table(key, data) VALUES(?, ?)');
    try {
      for (var i = 0; i < decoded.length; i++) {
        final row = decoded[i];
        if (row is! Map<String, dynamic>) continue;
        final key = (row['id'] ?? row['username'] ?? i).toString();
        stmt.execute([key, jsonEncode(row)]);
      }
    } finally {
      stmt.dispose();
    }
  }

  static List<Student> _defaultStudents() {
    return [
      Student(
        id: "S001",
        name: "Tendai Moyo",
        password: "password",
        schoolEmail: "tendai@africauniversity.ac.zw",
        schoolId: "S001",
        degree: "Computer Science",
        gender: "Female",
        medicalAid: "None",
        specialConditions: "None",
        hostelName: "A block",
        roomNumber: "A-001",
        contact: "+263 77 100 0001",
        address: "1 University Road",
        roommateNames: ["Rita", "Trust"],
      ),
      Student(
        id: "S002",
        name: "Ruth Chirwa",
        password: "password",
        schoolEmail: "ruth@africauniversity.ac.zw",
        schoolId: "S002",
        degree: "Business Management",
        gender: "Female",
        medicalAid: "Care",
        specialConditions: "None",
        hostelName: "I block",
        roomNumber: "I-003",
        contact: "+263 77 100 0002",
        address: "2 College Avenue",
        roommateNames: ["Nelson", "Patience"],
      ),
    ];
  }
}
