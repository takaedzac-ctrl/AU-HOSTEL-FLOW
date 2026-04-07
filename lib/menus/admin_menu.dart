import 'dart:io';
import '../storage/data_storage.dart';
import '../models/hostel.dart';

class AdminMenu {
  static void show() {
    while (true) {
      print("\n==== ADMIN DASHBOARD ====");
      print("1. View Hostels");
      print("2. Add Hostel");
      print("3. View Students");
      print("4. Logout");

      stdout.write("Select: ");
      String? choice = stdin.readLineSync();

      switch (choice) {
        case '1':
          for (var h in DataStorage.hostels) {
            print("${h.id} - ${h.name} (${h.gender})");
          }
          break;

        case '2':
          stdout.write("Hostel ID: ");
          String id = stdin.readLineSync()!;
          stdout.write("Name: ");
          String name = stdin.readLineSync()!;
          stdout.write("Gender: ");
          String gender = stdin.readLineSync()!;
          stdout.write("Warden: ");
          String warden = stdin.readLineSync()!;

          DataStorage.hostels.add(Hostel(
            id: id,
            name: name,
            gender: gender,
            warden: warden,
            rooms: [],
          ));
          DataStorage.saveHostels();
          print("Hostel added.");
          break;

        case '3':
          for (var s in DataStorage.students) {
            print("${s.id} - ${s.name}");
          }
          break;

        case '4':
          return;

        default:
          print("Invalid option");
      }
    }
  }
}