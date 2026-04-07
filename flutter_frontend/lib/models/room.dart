class Room {
  final String number;
  final int capacity;
  final List<String> occupantIds;

  Room({
    required this.number,
    required this.capacity,
    List<String>? occupantIds,
  }) : occupantIds = occupantIds ?? [];

  bool get isAvailable => occupantIds.length < capacity;

  int get availableSpots => capacity - occupantIds.length;

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      number: json['number'] ?? '',
      capacity: json['capacity'] ?? 0,
      occupantIds: List<String>.from(json['occupantIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'capacity': capacity,
        'occupantIds': occupantIds,
      };
}
