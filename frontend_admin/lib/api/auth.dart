import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:nimbus/api/constants.dart';
import 'package:nimbus/main.dart';

String _hashPassword(String password) {
  var bytes = utf8.encode(password);
  var digest = sha256.convert(bytes);
  return digest.toString();
}

/// it also encodes the pass
/// true if sucsess
Future<bool> auth(String email, String pass) async {
  pass = _hashPassword(pass);
  final resp;
  try {
    resp = await dio
        .post("http://127.0.0.1:8000/admin/auth", data: <String, String>{
      "email": email,
      "password": pass,
    });
  } catch (e) {
    print("Cought error: $e");
    return false;
  }

  authToken = resp.headers.value('Authorization');
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      if (authToken != null) {
        options.headers['Authorization'] = authToken;
      } else {
        print("Problem: called without auth token");
      }
      return handler.next(options);
    },
  ));

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
  pass = _hashPassword(pass);
  final resp = await dio.post(
    "$baseUrl/api/register-admin",
    data: <String, String?>{
      "email": email,
      "password": pass,
      "name": name,
      "last_name": lastName,
    },
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
  try {
    final response = await dio.post(
      url,
      data: {
        "valid_for_sec": validFor, // Convert to string to simulate Uint64
      },
    );

    if (response.statusCode == 200) {
      final uuid = response.data["uuid"];
      return "$baseBaseUrl/visitor/home/$uuid";
    } else {
      throw Exception(
          'Failed to generate link. Status code: ${response.statusCode}, Body: ${response.data}');
    }
  } catch (e) {
    return e.toString();
  }
}
