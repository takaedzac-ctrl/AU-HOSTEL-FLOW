import 'package:flutter/material.dart';

import '../models/hostel.dart';
import '../models/issue.dart';
import '../models/student.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'announcements_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final AuthService authService;
  final User admin;

  const AdminHomeScreen({super.key, required this.authService, required this.admin});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _enrollFormKey = GlobalKey<FormState>();
  final _hostelFormKey = GlobalKey<FormState>();
  final _issueFormKey = GlobalKey<FormState>();

  final _studentIdController = TextEditingController();
  final _blockIdController = TextEditingController();
  final _roomController = TextEditingController();

  final _newBlockId = TextEditingController();
  final _newBlockName = TextEditingController();
  final _newBlockWarden = TextEditingController();
  final _newBlockRooms = TextEditingController(text: '21');
  final _newBlockCapacity = TextEditingController(text: '2');

  final _issueStudentId = TextEditingController();
  final _issueTitle = TextEditingController();
  final _issueDetails = TextEditingController();
  final _searchController = TextEditingController();
  List<Student> _searchResults = [];

  List<Hostel> get _hostels => widget.authService.hostels;

  int get _occupied => _hostels.fold(0, (sum, h) => sum + h.occupied);
  int get _capacity => _hostels.fold(0, (sum, h) => sum + h.totalCapacity);

  String _issueAge(DateTime reportedAt, String status) {
    if (status.toLowerCase() == 'resolved') return 'Resolved';
    final diff = DateTime.now().difference(reportedAt);
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    return '${diff.inMinutes}m';
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _blockIdController.dispose();
    _roomController.dispose();
    _newBlockId.dispose();
    _newBlockName.dispose();
    _newBlockWarden.dispose();
    _newBlockRooms.dispose();
    _newBlockCapacity.dispose();
    _issueStudentId.dispose();
    _issueTitle.dispose();
    _issueDetails.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _searchStudent() {
    final query = _searchController.text.trim();
    setState(() {
      _searchResults = query.isEmpty
          ? []
          : widget.authService.searchStudents(query);
    });
  }

  void _processApplication(String studentId, bool accept) async {
    if (accept) {
      final ok = await widget.authService.acceptApplication(studentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Application accepted.' : 'No slots available; rejected.')),
      );
    } else {
      await widget.authService.rejectApplication(studentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application rejected.')),
      );
    }
    setState(() {});
  }

  Future<void> _updateIssue(String issueId, String status) async {
    final ok = await widget.authService.updateIssueStatus(issueId, status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Issue updated to $status.' : 'Failed to update issue status.')),
    );
    setState(() {});
  }

  Future<void> _toggleApplications(bool open) async {
    final ok = await widget.authService.setApplicationsOpen(open);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Applications ${open ? 'opened' : 'closed'}.' : 'Failed to update setting.')),
    );
    setState(() {});
  }

  Future<void> _warnStudent(String studentId) async {
    final ok = await widget.authService.addStudentWarning(studentId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Warning recorded for $studentId.' : 'Failed to record warning.')),
    );
    setState(() {});
  }

  Future<void> _toggleBlacklist(String studentId, bool isBlacklisted) async {
    final ok = await widget.authService.setStudentBlacklist(studentId, isBlacklisted);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Blacklist updated for $studentId.' : 'Failed to update blacklist.')),
    );
    setState(() {});
  }

  Future<void> _autoAllocateStudent(String studentId) async {
    final ok = await widget.authService.autoAllocateStudent(studentId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Student auto-allocated to a free room.'
              : 'Could not auto-allocate. No free gender-matching room.',
        ),
      ),
    );
    setState(() {});
  }

  void _showStudentsAllocationDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('All students and room allocations'),
          content: SizedBox(
            width: 700,
            height: 420,
            child: ListView.builder(
              itemCount: widget.authService.students.length,
              itemBuilder: (context, index) {
                final s = widget.authService.students[index];
                final unallocated = s.roomNumber.isEmpty;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text('${s.name} (${s.id})'),
                    subtitle: Text(
                      'Gender: ${s.gender} | Hostel: ${s.hostelName.isEmpty ? 'Unallocated' : s.hostelName} | '
                      'Room: ${s.roomNumber.isEmpty ? 'Unallocated' : s.roomNumber}',
                    ),
                    trailing: unallocated
                        ? ElevatedButton(
                            onPressed: () async {
                              await _autoAllocateStudent(s.id);
                              // ignore: use_build_context_synchronously
                              Navigator.of(ctx).pop();
                              _showStudentsAllocationDialog();
                            },
                            child: const Text('Auto allocate'),
                          )
                        : const Icon(Icons.check_circle, color: Colors.green),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showHostelsDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Hostels & Rooms Overview'),
          content: SizedBox(
            width: 700,
            height: 500,
            child: ListView.builder(
              itemCount: _hostels.length,
              itemBuilder: (context, index) {
                final h = _hostels[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ExpansionTile(
                    title: Text('${h.name} (Block ${h.id}) - ${h.gender}'),
                    subtitle: Text('Warden: ${h.warden} | Occupancy: ${h.occupied}/${h.totalCapacity}'),
                    children: h.rooms.map((r) {
                      return ListTile(
                        leading: const Icon(Icons.meeting_room),
                        title: Text('Room ${r.number}'),
                        subtitle: Text(
                          r.occupantIds.isEmpty 
                            ? 'Empty' 
                            : 'Occupants: ${r.occupantIds.join(", ")}',
                        ),
                        trailing: Text('${r.capacity - r.occupantIds.length} spots left'),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showEnrollDialog() {
    _studentIdController.clear();
    _blockIdController.clear();
    _roomController.clear();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Enroll Student'),
          content: Form(
            key: _enrollFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _studentIdController,
                  decoration: const InputDecoration(labelText: 'Student ID'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _blockIdController,
                  decoration: const InputDecoration(labelText: 'Block ID (A-L)'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _roomController,
                  decoration: const InputDecoration(labelText: 'Room e.g. A-001'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!_enrollFormKey.currentState!.validate()) return;
                final ok = await widget.authService.enrollStudentToRoom(
                  studentId: _studentIdController.text.trim(),
                  blockId: _blockIdController.text.trim(),
                  roomNumber: _roomController.text.trim(),
                );
                // ignore: use_build_context_synchronously
                Navigator.of(ctx).pop();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'Enrolled successfully.'
                        : 'Enrollment failed. Check room/block/student.'),
                  ),
                );
                setState(() {});
              },
              child: const Text('Enroll'),
            ),
          ],
        );
      },
    );
  }

  void _showAddHostelDialog() {
    _newBlockId.clear();
    _newBlockName.clear();
    _newBlockWarden.clear();
    _newBlockRooms.text = '21';
    _newBlockCapacity.text = '2';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Hostel / Block'),
          content: SingleChildScrollView(
            child: Form(
              key: _hostelFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _newBlockId,
                    decoration: const InputDecoration(labelText: 'Block ID'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _newBlockName,
                    decoration: const InputDecoration(labelText: 'Block name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _newBlockWarden,
                    decoration: const InputDecoration(labelText: 'Warden'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _newBlockRooms,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Rooms'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = int.tryParse(v);
                      if (val == null || val <= 0) return 'Invalid';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _newBlockCapacity,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Capacity per room'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = int.tryParse(v);
                      if (val == null || val <= 0) return 'Invalid';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!_hostelFormKey.currentState!.validate()) return;
                widget.authService.addHostel(
                  id: _newBlockId.text.trim(),
                  name: _newBlockName.text.trim(),
                  gender: 'Mixed',
                  warden: _newBlockWarden.text.trim(),
                  rooms: int.parse(_newBlockRooms.text.trim()),
                  capacity: int.parse(_newBlockCapacity.text.trim()),
                );
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Block added successfully.')),
                );
                setState(() {});
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showIssueDialog() {
    _issueStudentId.clear();
    _issueTitle.clear();
    _issueDetails.clear();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Report IT issue'),
          content: Form(
            key: _issueFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _issueStudentId,
                  decoration: const InputDecoration(labelText: 'Student ID'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _issueTitle,
                  decoration: const InputDecoration(labelText: 'Issue title'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _issueDetails,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Details'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!_issueFormKey.currentState!.validate()) return;
                widget.authService.submitIssue(Issue(
                  id: 'ISS-${DateTime.now().millisecondsSinceEpoch}',
                  studentId: _issueStudentId.text.trim(),
                  hostelId: '',
                  description: '${_issueTitle.text.trim()}: ${_issueDetails.text.trim()}',
                  reportDate: DateTime.now(),
                ));
                Navigator.of(ctx).pop();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Issue submitted to IT.')),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _showAdminsDialog() async {
    final admins = await widget.authService.getAdmins();
    if (!mounted) return;

    final newAdminUsernameController = TextEditingController();
    final newAdminPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Manage Admins'),
              content: SizedBox(
                width: 500,
                height: 400,
                child: Column(
                  children: [
                    const Text('Create New Admin', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: newAdminUsernameController,
                      decoration: const InputDecoration(labelText: 'Admin Username', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: newAdminPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Initial Password', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (newAdminUsernameController.text.trim().isEmpty || newAdminPasswordController.text.isEmpty) return;
                        final newAdmin = User(
                          username: newAdminUsernameController.text.trim(),
                          passwordHash: newAdminPasswordController.text,
                          role: UserRole.admin,
                        );
                        final ok = await widget.authService.addAdmin(newAdmin);
                        if (ok) {
                          final updatedAdmins = await widget.authService.getAdmins();
                          setDialogState(() {
                            admins.clear();
                            admins.addAll(updatedAdmins);
                          });
                          newAdminUsernameController.clear();
                          newAdminPasswordController.clear();
                        } else {
                          if (mounted) {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add admin.')));
                          }
                        }
                      },
                      child: const Text('Add Admin'),
                    ),
                    const Divider(height: 32),
                    const Text('Existing Admins', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: ListView.builder(
                        itemCount: admins.length,
                        itemBuilder: (context, i) {
                          final a = admins[i];
                          return ListTile(
                            leading: const Icon(Icons.admin_panel_settings),
                            title: Text(a.username),
                            subtitle: Text(a.name ?? 'No name set'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(6),
          child: Image.asset('assets/images/au_logo.png'),
        ),
        title: const Text('Admin Dashboard'),
        actions: [
           IconButton(
            icon: const Icon(Icons.campaign),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AnnouncementsScreen(
                authService: widget.authService,
                isAdmin: true,
                authorName: widget.admin.name?.isNotEmpty == true ? widget.admin.name! : widget.admin.username,
              )));
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(
                 authService: widget.authService,
                 admin: widget.admin,
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
              'assets/images/admin_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.85)),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Africa University Hostel Flow',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Admin control center: add blocks, enroll students, check room occupancy.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Blocks', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${_hostels.length}'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Occupancy', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('$_occupied/$_capacity'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Issues', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${widget.authService.issues.length}'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _showAddHostelDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add hostel/block'),
                ),
                ElevatedButton.icon(
                  onPressed: _showEnrollDialog,
                  icon: const Icon(Icons.how_to_reg),
                  label: const Text('Enroll student'),
                ),
                ElevatedButton.icon(
                  onPressed: _showIssueDialog,
                  icon: const Icon(Icons.report_problem),
                  label: const Text('Report IT issue'),
                ),
                ElevatedButton.icon(
                  onPressed: _showStudentsAllocationDialog,
                  icon: const Icon(Icons.people),
                  label: const Text('View students & allocate'),
                ),
                ElevatedButton.icon(
                  onPressed: _showHostelsDialog,
                  icon: const Icon(Icons.apartment),
                  label: const Text('View Hostels & Rooms'),
                ),
                ElevatedButton.icon(
                  onPressed: _showAdminsDialog,
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Manage admins'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Application window',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(widget.authService.applicationsOpen ? 'OPEN' : 'CLOSED'),
                    const SizedBox(width: 8),
                    Switch(
                      value: widget.authService.applicationsOpen,
                      onChanged: (value) {
                        _toggleApplications(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Search student', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search by ID, name, email',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _searchStudent,
                          child: const Text('Search'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_searchResults.isNotEmpty)
                      ..._searchResults.map(
                        (s) => ListTile(
                          title: Text('${s.name} (${s.id})'),
                          subtitle: Text(
                            'Room: ${s.roomNumber.isEmpty ? 'Not allocated' : s.roomNumber} | '
                            'Warnings: ${s.warningCount}/3 | Blacklisted: ${s.isBlacklisted ? 'Yes' : 'No'}',
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              TextButton(
                                onPressed: () => _warnStudent(s.id),
                                child: const Text('Warn'),
                              ),
                              TextButton(
                                onPressed: () => _toggleBlacklist(s.id, !s.isBlacklisted),
                                child: Text(s.isBlacklisted ? 'Unban' : 'Ban'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const Text('No search results.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reported issues', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (widget.authService.issues.isEmpty)
                      const Text('No issues reported yet.')
                    else
                      ...widget.authService.issues.map((issue) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text('Student ${issue.studentId} • ${issue.status.toUpperCase()}'),
                            subtitle: Text(
                              '${issue.description}\nAge (unresolved): ${_issueAge(issue.reportDate, issue.status)}',
                            ),
                            isThreeLine: true,
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                TextButton(
                                  onPressed: () => _updateIssue(issue.id, 'in_progress'),
                                  child: const Text('In progress'),
                                ),
                                TextButton(
                                  onPressed: () => _updateIssue(issue.id, 'resolved'),
                                  child: const Text('Resolve'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pending applications', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (widget.authService.applications.isEmpty)
                      const Text('No pending applications.')
                    else
                      ...widget.authService.applications
                          .where((a) => a.status == 'Pending')
                          .map(
                        (app) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text('Student ${app.studentId}'),
                              subtitle: Text('Preference: ${app.hostelPreference}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    onPressed: () => _processApplication(app.studentId, true),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    onPressed: () => _processApplication(app.studentId, false),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _hostels.length,
                itemBuilder: (context, index) {
                  final block = _hostels[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ExpansionTile(
                      title: Text('${block.name} (${block.gender})'),
                      subtitle: Text(
                          'Rooms: ${block.roomCount}, occupied: ${block.occupied}, available: ${block.availableSpots}'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Warden: ${block.warden}'),
                              const SizedBox(height: 8),
                              const Text('First 5 rooms:'),
                              ...block.rooms.take(5).map((room) {
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    room.isAvailable ? Icons.check_circle : Icons.lock,
                                    color: room.isAvailable ? Colors.green : Colors.red,
                                  ),
                                  title: Text(room.number),
                                  subtitle: Text('${room.occupantIds.length}/${room.capacity}'),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
