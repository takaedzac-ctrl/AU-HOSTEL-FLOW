import 'package:au_hostel_flow/api_server.dart';

void main() async {
  final server = ApiServer();
  await server.startServer();
}