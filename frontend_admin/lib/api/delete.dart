import 'package:nimbus/api/constants.dart';
import 'package:nimbus/main.dart';

Future<bool> deleteProject(int projectId) async {
  final url = '$baseUrl/api/projects/$projectId';

  final response = await dio.delete(url);

  if (response.statusCode == 200) {
    // Successfully deleted
    return true;
  } else {
    // Failed to delete
    print('Failed to delete project: ${response.statusCode}');
    return false;
  }
}
