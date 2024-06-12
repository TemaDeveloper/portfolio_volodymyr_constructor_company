import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nimbus/api/constants.dart';

class UpdateProjectRequest {
  final String? name;
  final String? description;
  final int? year;
  final String? country;

  UpdateProjectRequest({
    this.name,
    this.description,
    this.year,
    this.country,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'year': year,
        'country': country,
      };
}

Future<bool> updateProject(int projectId, UpdateProjectRequest project) async {
  final url = "$baseUrl/api/projects/$projectId";

  // Create multipart request
  final request = http.MultipartRequest('PATCH', Uri.parse(url));

  // Add JSON data as a field
  request.fields['json'] = json.encode(project.toJson());

  // Send the request
  final response = await request.send();

  // Check the status code
  if (response.statusCode == 200) {
    return true;
  } else {
    print('Failed to update project: ${response.statusCode}');
    return false;
  }
}
