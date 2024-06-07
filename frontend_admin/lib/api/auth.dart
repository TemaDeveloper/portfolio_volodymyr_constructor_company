import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:nimbus/api/constants.dart';

String _hashPassword(String password) {
  var bytes = utf8.encode(password);
  var digest = sha256.convert(bytes);
  return digest.toString();
}

/// it also encodes the pass
/// true if sucsess
Future<bool> auth(String email, String pass) async {
  pass = _hashPassword(pass);
  final resp = await http.post(
    Uri.parse("$baseUrl/auth"),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{"email": email, "password": pass}),
  );

  if (resp.statusCode == 200) {
    return true;
  } else {
    return false;
  }
}

enum RegisterStatus {
  Created,
  AlreadyExists,
  InternalServerError
}

Future<RegisterStatus> registerAdmin(
    {required String email,
    required String pass,
    String? name,
    String? lastName}) async {
  pass = _hashPassword(pass);
  final resp = await http.post(
    Uri.parse("$baseUrl/api/register-admin"),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String?>{
      "email": email,
      "password": pass,
      "name": name,
      "last_name": lastName,
    }),
  );
  
  if (resp.statusCode == 201) { // CREATED
    return RegisterStatus.Created;
  } else if (resp.statusCode == 409) { // Duplicate
    return RegisterStatus.AlreadyExists;
  } else {
    return RegisterStatus.InternalServerError;
  }
}
