import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:io';

class Helpers {
  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  static void clearScreen() {
    print("\x1B[2J\x1B[0;0H");
  }

  static String input(String message) {
    stdout.write(message);
    return stdin.readLineSync() ?? "";
  }

  static void pause() {
    stdout.write("\nPress Enter to continue...");
    stdin.readLineSync();
  }
}