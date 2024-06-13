import 'dart:convert';
import 'package:dio/dio.dart';
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
  try {
    final response = await Dio().get('$baseUrl/api/projects/years');
    if (response.statusCode == 200) {
      // Directly use the response data as a JSON map
      Map<String, dynamic> jsonResponse = response.data;
      List<int> intYears = List<int>.from(jsonResponse['years']);
      List<String> stringYears = intYears.map((year) => year.toString()).toList();
      return stringYears;
    } else {
      print("Error fetching years: ${response.statusCode}");
    }
  } on DioError catch (e) {
    print("Dio error fetching years: $e");
  }
  return null;
}
