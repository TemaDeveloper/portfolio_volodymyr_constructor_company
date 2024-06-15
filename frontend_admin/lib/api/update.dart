import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:nimbus/api/constants.dart';
 
class UpdateProjectRequest {
  final String? name;
  final String? description;
  final int? year;
  final String? country;
  final List<String>? pictures;
  final List<String>? videos;

  UpdateProjectRequest({
    this.name,
    this.description,
    this.year,
    this.country,
    this.pictures,
    this.videos,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'year': year,
        'country': country,
        'pictures': pictures,
        'videos': videos,
      };
}

Future<bool> updateProject(int projectId, UpdateProjectRequest project) async {
  final url = "$baseUrl/api/projects/$projectId";
  try {
    final response = await Dio().patch(url, data: project.toJson());
    if (response.statusCode == 200) {
      return true;
    } else {
      print('Failed to update project: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    print("Cought: $e");
    return false;
  }

}
