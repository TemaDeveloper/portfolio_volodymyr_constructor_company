import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:nimbus/api/constants.dart';
import 'package:nimbus/api/file_picker_helper.dart'; // CustomPickedFile is defined here

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

  CreateProjectRequest({
    required this.name,
    required this.description,
    this.year,
    this.geoData,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'year': year,
        'geo_data': geoData?.toJson(),
      };
}

Future<bool> createProject(CreateProjectRequest project, List<CustomPickedFile> pictures) async {
  final url = "$baseUrl/api/projects";

  // Create multipart request
  final request = http.MultipartRequest('POST', Uri.parse(url));

  // Add JSON data as a field
  request.fields['json'] = json.encode(project.toJson());

  // Add pictures as files
  for (CustomPickedFile picture in pictures) {
    request.files.add(http.MultipartFile.fromBytes(
      'pictures',
      picture.bytes,
      filename: picture.name,
      contentType: MediaType('image', 'jpeg'),
    ));
  }

  // Send the request
  final response = await request.send();

  // Check the status code
  if (response.statusCode == 200) {
    return true;
  } else {
    print('Failed to upload project: ${response.statusCode}');
    return false;
  }
}