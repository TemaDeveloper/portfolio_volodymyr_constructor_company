import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nimbus/api/constants.dart';

class Years {
  final List<String> years;

  Years({required this.years});

  factory Years.fromJson(Map<String, dynamic> json) {
    return Years(
      years: List<String>.from(json['years']),
    );
  }
}

Future<List<String>?> getYears() async {
  final response = await http.get(Uri.parse("$baseUrl/api/projects/years"));

  if (response.statusCode == 200) {
    Map<String, dynamic> jsonResponse = json.decode(response.body);
    Years yearsResponse = Years.fromJson(jsonResponse);
    return yearsResponse.years;
  } else {
    return null;
  }
}

