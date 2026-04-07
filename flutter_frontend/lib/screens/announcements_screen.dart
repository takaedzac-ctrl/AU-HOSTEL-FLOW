import 'package:flutter/material.dart';
import '../models/announcement.dart';
import '../services/auth_service.dart';

class AnnouncementsScreen extends StatefulWidget {
  final AuthService authService;
  final bool isAdmin;
  final String authorName;

  const AnnouncementsScreen({
    super.key,
    required this.authService,
    required this.isAdmin,
    required this.authorName,
  });

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<Announcement> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    final data = await widget.authService.getAnnouncements();
    // Sort by date descending
    data.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _announcements = data;
      _isLoading = false;
    });
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) return;
              final ann = Announcement(
                id: '',
                title: titleController.text.trim(),
                content: contentController.text.trim(),
                date: DateTime.now(),
                author: widget.authorName,
              );
              Navigator.of(ctx).pop();
              await widget.authService.addAnnouncement(ann);
              _loadAnnouncements();
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAnnouncements),
        ],
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: _showAddDialog,
              child: const Icon(Icons.add),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
              ? const Center(child: Text('No announcements yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _announcements.length,
                  itemBuilder: (ctx, i) {
                    final ann = _announcements[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ann.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Posted by ${ann.author} on ${ann.date.toLocal().toString().split('.')[0]}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            const Divider(),
                            Text(ann.content, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
