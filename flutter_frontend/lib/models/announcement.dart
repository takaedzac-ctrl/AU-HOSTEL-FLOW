class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String author;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.author,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      author: json['author'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'date': date.toIso8601String(),
        'author': author,
      };
}
