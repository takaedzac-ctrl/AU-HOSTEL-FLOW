import 'api_server.dart';

void main() async {
  print("====================================");
  print("     AU HOSTEL-FLOW API SERVER");
  print("====================================");

  final server = ApiServer();
  await server.startServer();
}