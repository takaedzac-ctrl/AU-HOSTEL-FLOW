import 'dart:io';
import '../storage/data_storage.dart';
import '../models/student.dart';

class Authentication {
  static bool loginAdmin() {
    stdout.write("Admin Username: ");
    String? user = stdin.readLineSync();

    stdout.write("Password: ");
    String? pass = stdin.readLineSync();

    if (user == "admin" && pass == "admin123") {
      print("Admin login successful!");
      return true;
    }

    print("Invalid credentials.");
    return false;
  }

  static Student? loginStudent() {
    stdout.write("Student ID: ");
    String? id = stdin.readLineSync();

    stdout.write("Password: ");
    String? pass = stdin.readLineSync();

    for (var student in DataStorage.students) {
      if (student.id == id && student.password == pass) {
        print("Login successful. Welcome ${student.name}");
        return student;
      }
    }

    print("Invalid credentials.");
    return null;
  }
}