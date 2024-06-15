import 'package:nimbus/api/constants.dart';
import 'package:nimbus/main.dart';

class Project {
  final int year;
  final String country;
  final double latitude;
  final double longitude;
  final List<String> pictures;
  final List<String> videos;
  final String description;
  final int id;
  final String name;

  Project({
    required this.year,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.pictures,
    required this.videos,
    required this.description,
    required this.id,
    required this.name,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      year: json['year'],
      country: json['country'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      pictures: List<String>.from(json['pictures']),
      videos: List<String>.from(json['videos']),
      description: json['description'],
      id: json['id'],
      name: json['name'],
    );
  }
}

Future<List<Project>?> getProjects({String? country, int? year}) async {
  Map<String, String> queryParams = {};
  String url = "$baseUrl/api/projects";

  if (country != null) {
    queryParams['country'] = country;
  }
  if (year != null) {
    queryParams['year'] = year.toString();
  }

  String queryString = Uri(queryParameters: queryParams).query;
  url = queryString.isNotEmpty ? '$url?$queryString' : url;
  final response = await dio.get(url);
  try {
    if (response.statusCode == 200) {
      List<Project> projects = (response.data['projects'] as List)
          .map((item) => Project.fromJson(item))
          .toList();
      return projects;
    } else {
      return null;
    }
  } catch (e) {
    print("Caught error: $e");
    return null;
  }
}
