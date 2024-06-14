import 'package:dio/dio.dart';
import 'package:nimbus/api/constants.dart';

Future<List<String>> uploadPictures(List<MultipartFile> pictureFiles) async {
  final Dio dio = Dio();
  const String url = "$baseUrl/api/projects/pictures";
  List<String> fileIds = [];

  try {
    FormData formData = FormData();
    for (var picture in pictureFiles) {
      formData.files.add(MapEntry(
        'files',
        picture
      ));
    }

    final response = await dio.post(url, data: formData);
    if (response.statusCode == 200) {
      fileIds = List<String>.from(response.data['file_ids']);
    } else {
      print("Failed to upload pictures: ${response.statusCode}");
    }
  } catch (e) {
    print("Error uploading pictures: $e");
  }

  return fileIds;
}

Future<List<String>> uploadVideos(List<MultipartFile> videoFiles) async {
  final Dio dio = Dio();
  const String url = "$baseUrl/api/projects/videos";
  List<String> fileIds = [];

  try {
    FormData formData = FormData();
    for (var video in videoFiles) {
      formData.files.add(MapEntry(
        'files',
        video
      ));
    }

    final response = await dio.post(url, data: formData);
    if (response.statusCode == 200) {
      fileIds = List<String>.from(response.data['file_ids']);
    } else {
      print("Failed to upload videos: ${response.statusCode}");
    }
  } catch (e) {
    print("Error uploading videos: $e");
  }

  return fileIds;
}
