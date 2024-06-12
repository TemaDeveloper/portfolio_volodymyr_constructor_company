import 'package:http/http.dart' as http;
import 'package:nimbus/api/constants.dart';

Future<bool> deleteProject(int projectId) async {
  final http.Client _client = http.Client();
  final url = Uri.parse('$baseUrl/api/projects/$projectId');

  final response = await _client.delete(url);

  if (response.statusCode == 204) {
    // Successfully deleted
    return true;
  } else {
    // Failed to delete
    print('Failed to delete project: ${response.statusCode}');
    return false;
  }
}
