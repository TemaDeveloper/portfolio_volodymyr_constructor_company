import 'package:http/http.dart' as http;
import 'package:nimbus/api/constants.dart';

Future<void> deleteFile(String fileName) async {
  final url = Uri.parse('$baseUrl/api/projects/storage/delete/$fileName');
  
  final response = await http.delete(url);

  if (response.statusCode == 200) {
    print('File deleted successfully.');
  } else {
    print('Failed to delete the file. Status code: ${response.statusCode}');
  }
}
