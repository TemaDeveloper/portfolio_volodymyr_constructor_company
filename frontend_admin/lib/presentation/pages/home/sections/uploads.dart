import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nimbus/api/constants.dart';

Future<bool> uploadImages(List<XFile> mediaFiles) async {
  final url = "$baseUrl/api/upload_images";

  // Create multipart request
  final request = http.MultipartRequest('POST', Uri.parse(url));

  // Filter images and add them as files
  for (XFile file in mediaFiles.where((file) => file.mimeType?.startsWith('image/') ?? false)) {
    final String mimeType = file.mimeType ?? 'image/jpeg';
    request.files.add(http.MultipartFile.fromBytes(
      'images',
      await file.readAsBytes(),
      filename: file.name,
      contentType: MediaType.parse(mimeType),
    ));
  }

  // Send the request
  try {
    final response = await request.send();

    // Check the status code
    if (response.statusCode == 200) {
      return true;
    } else {
      print('Failed to upload images: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('Error uploading images: $e');
    return false;
  }
}

Future<bool> uploadVideos(List<XFile> mediaFiles) async {
  final url = "$baseUrl/api/upload_videos";

  // Create multipart request
  final request = http.MultipartRequest('POST', Uri.parse(url));

  // Filter videos and add them as files
  for (XFile file in mediaFiles.where((file) => file.mimeType?.startsWith('video/') ?? false)) {
    final String mimeType = file.mimeType ?? 'video/mp4';
    request.files.add(http.MultipartFile.fromBytes(
      'videos',
      await file.readAsBytes(),
      filename: file.name,
      contentType: MediaType.parse(mimeType),
    ));
  }

  // Send the request
  try {
    final response = await request.send();

    // Check the status code
    if (response.statusCode == 200) {
      return true;
    } else {
      print('Failed to upload videos: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('Error uploading videos: $e');
    return false;
  }
}
