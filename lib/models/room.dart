class Room {
  String number;
  int capacity;
  List<String> occupantIds;

  Room({
    required this.number,
    required this.capacity,
    List<String>? occupantIds,
  }) : occupantIds = occupantIds ?? [];

  bool get isAvailable => occupantIds.length < capacity;
  int get availableSpots => capacity - occupantIds.length;

  Map<String, dynamic> toJson() => {
        'number': number,
        'capacity': capacity,
        'occupantIds': occupantIds,
      };

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      number: json['number'] ?? '',
      capacity: json['capacity'] ?? 0,
      occupantIds: List<String>.from(json['occupantIds'] ?? []),
    );
  }
}