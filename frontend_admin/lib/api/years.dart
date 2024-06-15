import 'package:nimbus/api/constants.dart';
import 'package:nimbus/main.dart';

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
  final response = await dio.get('$baseUrl/api/projects/years');

  if (response.statusCode == 200) {
    List<int> intYears = List<int>.from(response.data);
    List<String> stringYears = intYears.map((year) => year.toString()).toList();
    return stringYears;
  } else {
    return null;
  }
}
