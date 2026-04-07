import 'dart:io';
import '../models/student.dart';

class StudentMenu {
  static void show(Student student) {
    while (true) {
      print("\n==== STUDENT DASHBOARD ====");
      print("1. View Profile");
      print("2. View Room Assignment");
      print("3. Logout");

      stdout.write("Select: ");
      String? choice = stdin.readLineSync();

      switch (choice) {
        case '1':
          print("ID: ${student.id}");
          print("Name: ${student.name}");
          break;

        case '2':
          print("Hostel: ${student.hostelName}");
          print("Room: ${student.roomNumber}");
          break;

        case '3':
          return;

        default:
          print("Invalid option");
      }
    }
  }
}