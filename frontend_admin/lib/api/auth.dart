import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
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
  // pass = _hashPassword(pass);
  final resp;
  try {
    resp = await Dio().post("http://127.0.0.1:8000/admin/auth", data: <String, String>{
      "email": email,
      "password": pass,
    });
  } catch (e) {
    print("Cought error: $e");
    return false;
  }

  print("Code: ${resp.statusCode}|Body: ${resp.data}");

  if (resp.statusCode == 200) {
    return true;
  } else {
    return false;
  }
}

enum RegisterStatus { Created, AlreadyExists, InternalServerError }

Future<RegisterStatus> registerAdmin(
    {required String email,
    required String pass,
    String? name,
    String? lastName}) async {
  // pass = _hashPassword(pass);
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

  if (resp.statusCode == 201) {
    // CREATED
    print("Registered(Email=$email|password=$pass)");
    return RegisterStatus.Created;
  } else if (resp.statusCode == 409) {
    // Duplicate
    return RegisterStatus.AlreadyExists;
  } else {
    return RegisterStatus.InternalServerError;
  }
}

/// Theoretically there is no point of failure
Future<String> issueVisitorLink({required int validFor}) async {
  final url = "$baseUrl/api/visitor";
  final response = await http.post(
    Uri.parse(url),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, int>{
      "valid_for_sec": validFor, // Convert to string to simulate Uint64
    }),
  );

  if (response.statusCode == 200) {
    final jsonResponse = json.decode(response.body);
    final uuid = jsonResponse["uuid"];
    return "$baseUrl/visitor/$uuid";
  } else {
    throw Exception(
        'Failed to generate link. Status code: ${response.statusCode}, Body: ${response.body}');
  }
}
