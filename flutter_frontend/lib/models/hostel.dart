import 'room.dart';

class Hostel {
  final String id;
  final String name;
  final String gender;
  final String warden;
  final List<Room> rooms;

  Hostel({
    required this.id,
    required this.name,
    required this.gender,
    required this.warden,
    required this.rooms,
  });

  int get totalCapacity => rooms.fold(0, (sum, room) => sum + room.capacity);
  int get occupied => rooms.fold(0, (sum, room) => sum + room.occupantIds.length);
  int get availableSpots => totalCapacity - occupied;
  int get roomCount => rooms.length;

  factory Hostel.fromJson(Map<String, dynamic> json) {
    return Hostel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      gender: json['gender'] ?? '',
      warden: json['warden'] ?? '',
      rooms: (json['rooms'] as List?)?.map((r) => Room.fromJson(r)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'gender': gender,
        'warden': warden,
        'rooms': rooms.map((r) => r.toJson()).toList(),
      };
}
