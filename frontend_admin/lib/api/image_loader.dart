// image_loader.dart

import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:nimbus/main.dart';

Future<Uint8List?> loadMedia(String mediaUrl) async {
  try {
    final response = await dio.get(
      mediaUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    if (response.statusCode == 200) {
      return Uint8List.fromList(response.data);
    } else {
      print('Error: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error fetching media: $e');
    return null;
  }
}
