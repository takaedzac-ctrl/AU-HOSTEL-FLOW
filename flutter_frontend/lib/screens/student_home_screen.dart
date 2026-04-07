import 'package:flutter/material.dart';

import '../models/application.dart';
import '../models/issue.dart';
import '../models/student.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'announcements_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final Student student;
  final AuthService authService;

  const StudentHomeScreen({
    super.key,
    required this.student,
    required this.authService,
  });

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final _applicationKey = GlobalKey<FormState>();
  final _schoolEmail = TextEditingController();
  final _schoolId = TextEditingController();
  final _degree = TextEditingController();
  final _gender = TextEditingController();
  final _medicalAid = TextEditingController();
  final _specialConditions = TextEditingController();
  final _issueTitleController = TextEditingController();
  final _issueDetailsController = TextEditingController();
  String _issueType = 'Maintenance';
  String _issueRoute = 'Admin & IT';
  DateTime? _checkIn;
  DateTime? _checkOut;

  @override
  void initState() {
    super.initState();
    final student = widget.student;
    _schoolEmail.text = student.schoolEmail;
    _schoolId.text = student.schoolId;
    _degree.text = student.degree;
    _gender.text = student.gender;
    _medicalAid.text = student.medicalAid;
    _specialConditions.text = student.specialConditions;
    _checkIn = student.checkIn;
    _checkOut = student.checkOut;
  }

  @override
  void dispose() {
    _schoolEmail.dispose();
    _schoolId.dispose();
    _degree.dispose();
    _gender.dispose();
    _medicalAid.dispose();
    _specialConditions.dispose();
    _issueTitleController.dispose();
    _issueDetailsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool checkIn) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    setState(() {
      if (checkIn) {
        _checkIn = date;
      } else {
        _checkOut = date;
      }
    });
  }

  void _submitApplication() async {
    if (!_applicationKey.currentState!.validate()) return;
    if (!widget.authService.canSubmitApplicationFor(widget.student.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Application not allowed right now (closed/full/already applied/blacklisted/warnings).',
          ),
        ),
      );
      return;
    }
    if (_checkIn == null || _checkOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick both check in and check out dates.')),
      );
      return;
    }

    final submitted = await widget.authService.submitAccommodationApplication(AccommodationApplication(
      id: '',
      studentId: widget.student.id,
      hostelPreference: _gender.text.trim().isEmpty ? 'Any' : _gender.text.trim(),
      submissionDate: DateTime.now(),
    ));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          submitted
              ? 'Application submitted. Admin will review.'
              : 'Application could not be submitted. Check policy restrictions.',
        ),
      ),
    );
  }

  void _updateProfile() async {
    if (!_applicationKey.currentState!.validate()) return;

    final updatedStudent = widget.student.copyWith(
      schoolEmail: _schoolEmail.text.trim(),
      schoolId: _schoolId.text.trim(),
      degree: _degree.text.trim(),
      gender: _gender.text.trim(),
      medicalAid: _medicalAid.text.trim(),
      specialConditions: _specialConditions.text.trim(),
    );

    final ok = await widget.authService.updateStudent(updatedStudent);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Profile updated successfully.' : 'Failed to update profile.',
        ),
      ),
    );
  }

  void _submitIssue() async {
    if (_issueTitleController.text.trim().isEmpty || _issueDetailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all issue fields.')),
      );
      return;
    }

    final ok = await widget.authService.submitIssue(Issue(
      id: 'ISS-${DateTime.now().millisecondsSinceEpoch}',
      studentId: widget.student.id,
      hostelId: widget.student.hostelName,
      description:
          'Route: $_issueRoute | Type: $_issueType | ${_issueTitleController.text.trim()}: ${_issueDetailsController.text.trim()}',
      reportDate: DateTime.now(),
    ));

    if (!mounted) return;
    _issueTitleController.clear();
    _issueDetailsController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Issue submitted successfully.' : 'Failed to submit issue.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(6),
          child: Image.asset('assets/images/au_logo.png'),
        ),
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AnnouncementsScreen(
                authService: widget.authService,
                isAdmin: false,
                authorName: widget.student.name.isNotEmpty ? widget.student.name : widget.student.id,
              )));
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(
                 authService: widget.authService,
                 student: widget.student,
              )));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => LoginScreen(onToggleTheme: () {}),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/library_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.86)),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${student.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Student ID: ${student.id}', style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 14),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Accommodation info', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Hostel: ${student.hostelName.isEmpty ? 'Not allocated' : student.hostelName}'),
                    Text('Room: ${student.roomNumber.isEmpty ? 'Not allocated' : student.roomNumber}'),
                    Text('Check-in: ${student.checkIn?.toLocal().toIso8601String().split('T').first ?? 'N/A'}'),
                    Text('Check-out: ${student.checkOut?.toLocal().toIso8601String().split('T').first ?? 'N/A'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Accommodation application', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Form(
                      key: _applicationKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _schoolEmail,
                            decoration: const InputDecoration(labelText: 'School email'),
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                          TextFormField(
                            controller: _schoolId,
                            decoration: const InputDecoration(labelText: 'School ID'),
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                          TextFormField(
                            controller: _degree,
                            decoration: const InputDecoration(labelText: 'Degree'),
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                          TextFormField(
                            controller: _gender,
                            decoration: const InputDecoration(labelText: 'Gender'),
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                          TextFormField(
                            controller: _medicalAid,
                            decoration: const InputDecoration(labelText: 'Medical aid'),
                          ),
                          TextFormField(
                            controller: _specialConditions,
                            decoration: const InputDecoration(labelText: 'Special conditions'),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => _pickDate(true),
                                  child: Text(_checkIn == null
                                      ? 'Select check-in'
                                      : 'Check-in: ${_checkIn!.toLocal().toIso8601String().split('T').first}'),
                                ),
                              ),
                              Expanded(
                                child: TextButton(
                                  onPressed: () => _pickDate(false),
                                  child: Text(_checkOut == null
                                      ? 'Select check-out'
                                      : 'Check-out: ${_checkOut!.toLocal().toIso8601String().split('T').first}'),
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: widget.authService.canSubmitApplicationFor(widget.student.id)
                                ? _submitApplication
                                : null,
                            child: const Text('Submit application'),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _updateProfile,
                            child: const Text('Update Profile'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Report an Issue', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _issueType,
                      decoration: const InputDecoration(labelText: 'Issue type'),
                      items: const [
                        DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance / Room repair')),
                        DropdownMenuItem(value: 'IT', child: Text('IT issue')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _issueType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _issueRoute,
                      decoration: const InputDecoration(labelText: 'Send to'),
                      items: const [
                        DropdownMenuItem(value: 'Admin & IT', child: Text('Administrators and IT department')),
                        DropdownMenuItem(value: 'Admin', child: Text('Administrators only')),
                        DropdownMenuItem(value: 'IT', child: Text('IT department only')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _issueRoute = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _issueTitleController,
                      decoration: const InputDecoration(labelText: 'Issue title'),
                    ),
                    TextFormField(
                      controller: _issueDetailsController,
                      decoration: const InputDecoration(
                        labelText: 'Issue details (room/maintenance/IT)',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _submitIssue,
                      child: const Text('Submit Issue'),
                    ),
                  ],
                ),
              ),
            ),
            ],
          ),
          ),
        ],
      ),
    );
  }
}
