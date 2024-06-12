import 'package:dio/dio.dart';
import 'package:nimbus/api/constants.dart';

class CountriesResponse {
  final List<String> countries;

  CountriesResponse({required this.countries});

  factory CountriesResponse.fromJson(Map<String, dynamic> json) {
    return CountriesResponse(
      countries: List<String>.from(json['countries']),
    );
  }
}

Future<List<String>?> getCountries({int? year}) async {
  try {
    String rootUrl = '$baseUrl/api/countries';
    Map<String, String> queryParams = {};

    if (year != null) {
      queryParams['year'] = year.toString();
    }

    String queryString = Uri(queryParameters: queryParams).query;
    String url = queryString.isNotEmpty ? '$rootUrl?$queryString' : rootUrl;

    final response = await Dio().get(url);
    if (response.statusCode == 200) {
      // Directly use the response data as a JSON map
      Map<String, dynamic> jsonResponse = response.data;
      CountriesResponse countriesResponse = CountriesResponse.fromJson(jsonResponse);
      return countriesResponse.countries;
    } else {
      print("Error fetching countries: ${response.statusCode}");
    }
  } on DioException catch (e) {
    print("Dio error fetching countries: $e");
  }
  return null;
}
