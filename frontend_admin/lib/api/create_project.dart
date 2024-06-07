import 'dart:convert';
import 'dart:html'; // For FileUploadInputElement
import 'package:http/http.dart' as http;

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

Future<bool> uploadProject(CreateProjectRequest project, List<File> pictures) async {
  const String url = 'https://yourapi.com/upload_project';

  // Convert project to JSON
  String projectJson = json.encode(project.toJson());

  // Create a FormData object
  FormData formData = FormData();

  // Add JSON data
  formData.append('json', projectJson);

  // Add pictures
  for (int i = 0; i < pictures.length; i++) {
    formData.appendBlob('pictures', pictures[i], pictures[i].name);
  }

  // Perform the POST request
  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'multipart/form-data',
    },
    body: formData,
  );

  // Check the status code
  if (response.statusCode == 200) {
    return true;
  } else {
    print('Failed to upload project: ${response.statusCode}');
    return false;
  }
}
