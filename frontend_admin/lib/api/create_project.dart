import 'package:dio/dio.dart';
import 'package:nimbus/api/constants.dart';
import 'package:nimbus/api/file_picker_helper.dart';
import 'package:nimbus/api/upload.dart';
import 'package:nimbus/main.dart';

class GeoData {
  final String country;
  final double latitude;
  final double longitude;

  GeoData({
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
      };
}

class CreateProjectRequest {
  final String name;
  final String description;
  final int? year;
  final GeoData? geoData;
  final List<String> pictures;
  final List<String> videos;

  CreateProjectRequest({
    required this.name,
    required this.description,
    this.year,
    this.geoData,
    this.pictures = const [],
    this.videos = const [],
  });

  CreateProjectRequest copyWith({
    List<String>? pictures,
    List<String>? videos,
  }) {
    return CreateProjectRequest(
      name: this.name,
      description: this.description,
      year: this.year,
      geoData: this.geoData,
      pictures: pictures ?? this.pictures,
      videos: videos ?? this.videos,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'year': year,
        'geo_data': geoData?.toJson(),
        'pictures': pictures,
        'videos': videos,
      };
}

class ProjectResponse {
  final int id;
  final int year;
  final String country;
  final List<String> pictures;
  final List<String> videos;

  ProjectResponse({
    required this.id,
    required this.year,
    required this.country,
    required this.pictures,
    required this.videos,
  });

  factory ProjectResponse.fromJson(Map<String, dynamic> json) {
    return ProjectResponse(
      id: json['id'],
      year: json['year'],
      country: json['country'],
      pictures: List<String>.from(json['pictures']),
      videos: List<String>.from(json['videos']),
    );
  }
}

Future<ProjectResponse?> createProject(
  CreateProjectRequest project,
  List<CustomPickedFile> pictures,
  List<CustomPickedFile> videos,
) async {

  try {
    ;
    List<String> pictureIds = await uploadPictures(pictures.map((p) => p.toMultipartFile()).toList());
    List<String> videoIds = await uploadVideos(videos.map((p) => p.toMultipartFile()).toList());

    project = project.copyWith(pictures: pictureIds, videos: videoIds);

    final response = await dio.post("$baseUrl/api/projects", data: project.toJson());
    if (response.statusCode == 200) {
      return ProjectResponse.fromJson(response.data);
    } else {
      print("Failed to create project: ${response.statusCode}");
      return null;
    }
  } catch (e) {
    print("Error creating project: $e");
    return null;
  }
}
