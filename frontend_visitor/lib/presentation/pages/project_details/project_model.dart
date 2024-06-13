import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nimbus/api/constants.dart';

class Project {
  final int year;
  final String country;
  final double latitude;
  final double longitude;
  final List<String> pictures;
  final String description;
  final int id;
  final String name;

  Project({
    required this.year,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.pictures,
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
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    List<dynamic> body = json.decode(response.body)["projects"];
    List<Project> projects =
        body.map((dynamic item) => Project.fromJson(item)).toList();
    return projects;
  } else {
    return null;
  }
}
