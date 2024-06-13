import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:nimbus/api/constants.dart';
import 'package:nimbus/api/file_picker_helper.dart';
import 'package:nimbus/api/upload.dart'; // CustomPickedFile is defined here

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
    String? name,
    String? description,
    int? year,
    GeoData? geoData,
    List<String>? pictures,
    List<String>? videos,
  }) {
    return CreateProjectRequest(
      name: name ?? this.name,
      description: description ?? this.description,
      year: year ?? this.year,
      geoData: geoData ?? this.geoData,
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

Future<ProjectResponse?> createProject(CreateProjectRequest project, List<CustomPickedFile> pictures, List<CustomPickedFile> videos) async {
  final UploadClientApi uploadApi = UploadClientApi();
  List<String> pictureIds = [];
  List<String> videoIds = [];

  try {
    // Convert CustomPickedFile to MultipartFile
    List<MultipartFile> pictureFiles = pictures.map((picture) => MultipartFile.fromBytes(
      picture.bytes,
      filename: picture.name,
      contentType: MediaType('image', 'jpeg'),
    )).toList();

    List<MultipartFile> videoFiles = videos.map((video) => MultipartFile.fromBytes(
      video.bytes,
      filename: video.name,
      contentType: MediaType('video', 'mp4'),
    )).toList();

    // Upload pictures and videos
    if (pictureFiles.isNotEmpty) {
      pictureIds = await uploadApi.uploadPictures(pictureFiles);
    }
    if (videoFiles.isNotEmpty) {
      videoIds = await uploadApi.uploadVideos(videoFiles);
    }

    // Create project request with uploaded file IDs
    final url = "$baseUrl/api/projects";
    final request = http.MultipartRequest('POST', Uri.parse(url));

    final projectWithIds = project.copyWith(
      pictures: pictureIds,
      videos: videoIds,
    );

    request.fields['json'] = json.encode(projectWithIds.toJson());

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final jsonMap = json.decode(responseData);
      return ProjectResponse.fromJson(jsonMap);
    } else {
      print('Failed to upload project: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error uploading project: $e');
    return null;
  }
}
