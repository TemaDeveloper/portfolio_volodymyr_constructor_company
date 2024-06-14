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
  final response = await http.get(Uri.parse('$baseUrl/projects/api/years'));

  if (response.statusCode == 200) {
    Map<String, dynamic> jsonResponse = json.decode(response.body);
    List<int> intYears = List<int>.from(jsonResponse['years']);
    List<String> stringYears = intYears.map((year) => year.toString()).toList();
    return stringYears;
  } else {
    return null;
  }
}
