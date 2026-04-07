import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LocalBackendBootstrap {
  static Future<void> ensureRunning() async {
    if (kIsWeb) return;
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return;

    final alreadyRunning = await _isBackendHealthy();
    if (alreadyRunning) return;

    final backendDir = _findBackendDirectory();
    if (backendDir == null) {
      debugPrint('LocalBackendBootstrap: unable to locate AU-HOSTEL-FLOW backend directory.');
      return;
    }

    try {
      debugPrint('LocalBackendBootstrap: launching backend from ${backendDir.path}');
      await Process.start(
        'dart',
        ['run', 'lib/main.dart'],
        workingDirectory: backendDir.path,
        runInShell: true,
      );

      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
        if (await _isBackendHealthy()) {
          debugPrint('LocalBackendBootstrap: backend is healthy.');
          return;
        }
      }
      debugPrint('LocalBackendBootstrap: backend did not become healthy in time.');
    } catch (error) {
      debugPrint('LocalBackendBootstrap: failed to launch backend: $error');
    }
  }

  static Future<bool> _isBackendHealthy() async {
    try {
      final response = await http
          .get(Uri.parse('http://localhost:8080/settings'))
          .timeout(const Duration(milliseconds: 700));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Directory? _findBackendDirectory() {
    try {
      var current = Directory.current;
      for (var depth = 0; depth < 6; depth++) {
        if (_isBackendFolder(current)) return current;

        final child = Directory('${current.path}${Platform.pathSeparator}AU-HOSTEL-FLOW');
        if (child.existsSync() && _isBackendFolder(child)) return child;

        if (current.parent.path == current.path) break;
        current = current.parent;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static bool _isBackendFolder(Directory directory) {
    final apiServer = File('${directory.path}${Platform.pathSeparator}lib${Platform.pathSeparator}api_server.dart');
    return apiServer.existsSync();
  }
}
