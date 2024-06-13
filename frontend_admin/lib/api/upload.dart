import 'package:dio/dio.dart';
import 'package:nimbus/api/constants.dart';

class UploadClientApi {
  final Dio dio = Dio(BaseOptions(baseUrl: '$baseUrl/api/projects'));

  Future<List<String>> uploadPictures(List<MultipartFile> files) async {
    final formData = FormData();
    for (var file in files) {
      formData.files.add(MapEntry(
        'files',
        file,
      ));
    }
    
    try {
      final response = await dio.post('/pictures', data: formData);
      if (response.statusCode == 200) {
        return List<String>.from(response.data['file_ids']);
      } else {
        throw Exception('Failed to upload pictures');
      }
    } on DioException catch (e) {
      throw Exception('Failed to upload pictures: ${e.message}');
    }
  }

  Future<List<String>> uploadVideos(List<MultipartFile> files) async {
    final formData = FormData();
    for (var file in files) {
      formData.files.add(MapEntry(
        'files',
        file,
      ));
    }

    try {
      final response = await dio.post('/videos', data: formData);
      if (response.statusCode == 200) {
        return List<String>.from(response.data['file_ids']);
      } else {
        throw Exception('Failed to upload videos');
      }
    } on DioException catch (e) {
      throw Exception('Failed to upload videos: ${e.message}');
    }
  }
}