import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:html' as html;

class CustomPickedFile {
  final Uint8List bytes;
  final String name;

  CustomPickedFile({required this.bytes, required this.name});
}

Future<CustomPickedFile?> pickFile() async {
  if (kIsWeb) {
    return await pickFileWeb();
  } else {
    return await pickFileMobile();
  }
}

Future<CustomPickedFile?> pickFileWeb() async {
  final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
  uploadInput.accept = 'image/*';
  uploadInput.click();
  await uploadInput.onChange.first;

  if (uploadInput.files != null && uploadInput.files!.isNotEmpty) {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(uploadInput.files!.first);
    await reader.onLoad.first;
    return CustomPickedFile(
      bytes: reader.result as Uint8List,
      name: uploadInput.files!.first.name,
    );
  }
  return null;
}

Future<CustomPickedFile?> pickFileMobile() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    final bytes = await pickedFile.readAsBytes();
    return CustomPickedFile(
      bytes: bytes,
      name: pickedFile.name,
    );
  }
  return null;
}
