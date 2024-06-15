import 'package:nimbus/api/constants.dart';
import 'package:nimbus/main.dart';

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
  String rootUrl = '${baseUrl}api/projects/countries';
  Map<String, String> queryParams = {};

  if (year != null) {
    queryParams['year'] = year.toString();
  }

  String queryString = Uri(queryParameters: queryParams).query;
  String url = queryString.isNotEmpty ? '$rootUrl?$queryString' : rootUrl;
  final response = await dio.get(url);

  if (response.statusCode == 200) {
    CountriesResponse countriesResponse = CountriesResponse.fromJson(response.data);
    return countriesResponse.countries;
  } else {
    return null;
  }
}
