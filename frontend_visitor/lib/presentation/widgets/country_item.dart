import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:nimbus/presentation/routes/router.gr.dart';

class CountryData {
  final String year;
  final String country;
  final double width;
  final double height;
  final double mobileWidth;
  final double mobileHeight;

  CountryData({
    required this.year,
    required this.country,
    required this.width,
    this.mobileHeight = 0.5,
    this.mobileWidth = 1.0,
    this.height = 0.4,
  });
}

class CountryItem extends StatelessWidget {
  const CountryItem({
    Key? key,
    required this.year,
    required this.country,
    required this.width,
    required this.height,
    this.bannerHeight,
    this.yearStyle,
    this.countryStyle,
    this.textColor = Colors.white,
    this.bannerColor,
  }) : super(key: key);

  final String year;
  final String country;
  final TextStyle? yearStyle;
  final TextStyle? countryStyle;
  final Color? bannerColor;
  final Color textColor;
  final double width;
  final double height;
  final double? bannerHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.black,
      child: Center(
        child: CountryCover(
          color: bannerColor ?? Colors.black.withOpacity(0.8),
          width: width,
          height: bannerHeight ?? height / 3,
          year: year,
          country: country,
          yearStyle: yearStyle,
          countryStyle: countryStyle,
        ),
      ),
    );
  }
}

class CountryCover extends StatelessWidget {
  const CountryCover({
    Key? key,
    required this.width,
    required this.height,
    required this.year,
    required this.country,
    this.indicatorColor = Colors.white,
    this.color,
    this.countryStyle,
    this.yearStyle,
  }) : super(key: key);

  final String year;
  final String country;
  final double width;
  final double height;
  final Color? color;
  final Color indicatorColor;
  final TextStyle? yearStyle;
  final TextStyle? countryStyle;

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () {
        context.router.push(
          ProjectsRoute(
            title: year,
            description: country,
          ),
        );
      },
      child: Container(
        width: width,
        height: height,
        color: color ?? Colors.black.withOpacity(0.8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                year,
                style: yearStyle ?? textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              SizedBox(height: 8.0),
              Text(
                country,
                style: countryStyle ?? textTheme.titleSmall?.copyWith(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
