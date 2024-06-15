import 'package:nimbus/api/constants.dart';
import 'package:nimbus/main.dart';

Future<void> deleteFile(String fileName) async {
  final url = '$baseUrl/api/projects/storage/delete/$fileName';
  final response = await dio.delete(url);

  if (response.statusCode == 200) {
    print('File deleted successfully.');
  } else {
    print('Failed to delete the file. Status code: ${response.statusCode}');
  }
}
