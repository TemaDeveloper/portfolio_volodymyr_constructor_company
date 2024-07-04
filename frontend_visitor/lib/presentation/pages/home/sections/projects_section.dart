import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:nimbus/api/constants.dart';
import 'package:nimbus/api/countries.dart';
import 'package:nimbus/api/years.dart';
import 'package:nimbus/presentation/layout/adaptive.dart';
import 'package:nimbus/presentation/widgets/content_area.dart';
import 'package:nimbus/presentation/widgets/country_item.dart';
import 'package:nimbus/presentation/widgets/nimbus_info_section.dart';
import 'package:nimbus/presentation/widgets/project_item.dart';
import 'package:nimbus/presentation/widgets/spaces.dart';
import 'package:nimbus/values/values.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:visibility_detector/visibility_detector.dart';

const double kSpacing = 20.0;
const double kRunSpacing = 16.0;

// class Years {
//   final List<String> years;

//   Years({required this.years});

//   factory Years.fromJson(Map<String, dynamic> json) {
//     return Years(
//       years: List<String>.from(json['years']),
//     );
//   }
// }

// Future<List<String>?> getYears() async {
//   try {
//     final response = await Dio().get('$baseUrl/api/years');
//     if (response.statusCode == 200) {
//       // Ensure response.data is treated as a JSON map
//       Map<String, dynamic> jsonResponse = response.data;
//       Years yearsResponse = Years.fromJson(jsonResponse);
//       return yearsResponse.years;
//     } else {
//       print("Error fetching years: ${response.statusCode}");
//     }
//   } on DioException catch (e) {
//     print("Dio error fetching years: $e");
//   }
//   return null;
// }

// class CountriesResponse {
//   final List<String> countries;

//   CountriesResponse({required this.countries});

//   factory CountriesResponse.fromJson(Map<String, dynamic> json) {
//     return CountriesResponse(
//       countries: List<String>.from(json['countries']),
//     );
//   }
// }

// Future<List<String>?> getCountries({int? year}) async {
//   try {
//     String rootUrl = '$baseUrl/api/countries';
//     Map<String, String> queryParams = {};

//     if (year != null) {
//       queryParams['year'] = year.toString();
//     }

//     String queryString = Uri(queryParameters: queryParams).query;
//     String url = queryString.isNotEmpty ? '$rootUrl?$queryString' : rootUrl;

//     final response = await Dio().get(url);
//     if (response.statusCode == 200) {
//       // Ensure response.data is treated as a JSON map
//       Map<String, dynamic> jsonResponse = response.data;
//       CountriesResponse countriesResponse = CountriesResponse.fromJson(jsonResponse);
//       return countriesResponse.countries;
//     } else {
//       print("Error fetching countries: ${response.statusCode}");
//     }
//   } on DioException catch (e) {
//     print("Dio error fetching countries: $e");
//   }
//   return null;
// }

class ProjectCategoryData {
  final String title;
  final int number;
  bool isSelected;

  ProjectCategoryData({
    required this.title,
    required this.number,
    this.isSelected = false,
  });
}

class ProjectsSection extends StatefulWidget {
  ProjectsSection({Key? key});

  @override
  _ProjectsSectionState createState() => _ProjectsSectionState();
}

class _ProjectsSectionState extends State<ProjectsSection> with SingleTickerProviderStateMixin {
  late AnimationController _projectController;
  late Animation<double> _projectScaleAnimation;
  List<List<ProjectData>> projects = [
    Data.allProjects,
    Data.branding,
    Data.packaging,
    Data.photograhy,
    Data.webDesign,
  ];
  late List<ProjectData> selectedProject;
  late List<ProjectCategoryData> projectCategories;

  List<String> years = [];
  bool isLoading = true;
  int? selectedYear;
  List<String> countries = [];

  @override
  void initState() {
    super.initState();
    selectedProject = projects[0];
    projectCategories = Data.projectCategories;
    _projectController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _projectScaleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _projectController,
        curve: Curves.fastOutSlowIn,
      ),
    );
    _fetchYears();
  }

  @override
  void dispose() {
    _projectController.dispose();
    super.dispose();
  }

  Future<void> _fetchYears() async {
    List<String>? fetchedYears = await getYears();
    if (fetchedYears != null) {
      setState(() {
        years = fetchedYears;
        isLoading = false;
      });
    } else {
      // Handle error
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchCountries(int? year) async {
    final fetchedCountries = await getCountries(year: year);
    if (fetchedCountries != null) {
      setState(() {
        countries = fetchedCountries;
      });
    }
  }

  Future<void> _playProjectAnimation() async {
    try {
      await _projectController.forward().orCancel;
    } on TickerCanceled {
      // the animation got canceled, probably because it was disposed of
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = widthOfScreen(context) - (getSidePadding(context) * 2);
    double contentAreaWidth = screenWidth;
    return VisibilityDetector(
      key: Key('project-section-sm'),
      onVisibilityChanged: (visibilityInfo) {
        double visiblePercentage = visibilityInfo.visibleFraction * 100;
        if (visiblePercentage > 20) {
          _playProjectAnimation();
        }
      },
      child: ResponsiveBuilder(
        refinedBreakpoints: RefinedBreakpoints(),
        builder: (context, sizingInformation) {
          double screenWidth = sizingInformation.screenSize.width;
          if (screenWidth < (RefinedBreakpoints().tabletLarge)) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: getSidePadding(context)),
              child: ContentArea(
                width: contentAreaWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNimbusInfoSectionSm(),
                    SpaceH40(),
                    Wrap(
                      spacing: kSpacing,
                      runSpacing: kRunSpacing,
                      children: _buildProjectCategories(),
                    ),
                    SpaceH40(),
                    Wrap(
                      runSpacing: assignHeight(context, 0.05),
                      children: _buildProjects(isMobile: true),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return VisibilityDetector(
              key: Key('project-section_lg'),
              onVisibilityChanged: (visibilityInfo) {
                double visiblePercentage = visibilityInfo.visibleFraction * 100;
                if (visiblePercentage > 40) {
                  _playProjectAnimation();
                }
              },
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: getSidePadding(context),
                    ),
                    child: ContentArea(
                      width: contentAreaWidth,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ContentArea(
                            width: contentAreaWidth * 0.6,
                            child: _buildNimbusInfoSectionLg(),
                          ),
                          Spacer(),
                        ],
                      ),
                    ),
                  ),
                  SpaceH40(),
                  Container(
                    width: widthOfScreen(context),
                    child: Wrap(
                      spacing: assignWidth(context, 0.025),
                      runSpacing: assignWidth(context, 0.025),
                      children: _buildProjects(),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildNimbusInfoSectionSm() {
    return NimbusInfoSection2(
      sectionTitle: StringConst.MY_WORKS,
      title1: StringConst.MEET_MY_PROJECTS,
      hasTitle2: false,
      body: StringConst.PROJECTS_DESC,
    );
  }

  Widget _buildNimbusInfoSectionLg() {
    return NimbusInfoSection1(
      sectionTitle: StringConst.MY_WORKS,
      title1: StringConst.MEET_MY_PROJECTS,
      hasTitle2: false,
      body: StringConst.PROJECTS_DESC,
      child: Wrap(
        spacing: kSpacing,
        runSpacing: kRunSpacing,
        children: _buildProjectCategories(),
      ),
    );
  }

  List<Widget> _buildProjectCategories() {
  List<Widget> items = [];

  for (int index = 0; index < years.length; index++) {
    items.add(
      ProjectCategory(
        title: years[index],
        number: 0,
        isSelected: selectedYear == int.parse(years[index]),
        onTap: () => onProjectCategoryTap(index), // Correct index used here
      ),
    );
  }
  return items;
}


  List<Widget> _buildProjects({bool isMobile = false}) {
    List<Widget> items = [];
    for (int index = 0; index < countries.length; index++) {
      items.add(
        CountryItem(
          width: isMobile
              ? assignWidth(context, 1.0)
              : assignWidth(context, 0.25),
          height: assignHeight(context, 0.2),
          year: selectedYear.toString(),
          country: countries[index],
        ),
      );
    }
    return items;
  }

  void onProjectCategoryTap(int index) {
  if (index >= 0 && index < years.length) {
    setState(() {
      selectedYear = int.parse(years[index]);
      fetchCountries(selectedYear);
    });
  } else {
    print("Index out of range: $index");
  }
}

}

class ProjectCategory extends StatefulWidget {
  ProjectCategory({
    required this.title,
    required this.number,
    this.titleColor = const Color.fromARGB(255, 255, 255, 255),
    this.numberColor = Colors.transparent,
    this.hoverColor = AppColors.primaryColor,
    this.titleStyle,
    this.numberStyle,
    this.onTap,
    this.isSelected = false,
  });

  final String title;
  final Color titleColor;
  final Color numberColor;
  final TextStyle? titleStyle;
  final int number;
  final Color hoverColor;
  final TextStyle? numberStyle;
  final GestureTapCallback? onTap;
  final bool isSelected;

  @override
  _ProjectCategoryState createState() => _ProjectCategoryState();
}

class _ProjectCategoryState extends State<ProjectCategory> with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _controller;
  late Color color;

  @override
  void initState() {
    super.initState();
    color = widget.titleColor;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 450),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(color: const Color.fromARGB(255, 42, 42, 42)),
        child: MouseRegion(
          onEnter: (e) => _mouseEnter(true),
          onExit: (e) => _mouseEnter(false),
          child: InkWell(
            onTap: widget.onTap,
            hoverColor: Colors.transparent,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: widget.title,
                    style: widget.titleStyle?.copyWith(
                      color: colorOfCategory(),
                    ) ??
                        textTheme.titleMedium?.copyWith(
                          fontSize: Sizes.TEXT_SIZE_16,
                          color: colorOfCategory(),
                        ),
                  ),
                  WidgetSpan(
                    child: widget.isSelected
                        ? numberOfProjectItems()
                        : FadeTransition(
                      opacity: _controller.view,
                      child: numberOfProjectItems(),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget numberOfProjectItems() {
    TextTheme textTheme = Theme.of(context).textTheme;

    return Transform.translate(
      offset: const Offset(2, -8),
      child: Text(
        "(${widget.number})",
        textScaleFactor: 0.7,
        style: widget.numberStyle?.copyWith(
          color: widget.hoverColor,
        ) ??
            textTheme.titleMedium?.copyWith(
              fontSize: Sizes.TEXT_SIZE_16,
              color: widget.hoverColor,
            ),
      ),
    );
  }

  void _mouseEnter(bool hovering) {
    setState(() {
      _isHovering = hovering;
    });
    if (hovering) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  Color colorOfSuperScript() {
    if (_isHovering) {
      return widget.hoverColor;
    } else if (widget.isSelected) {
      return widget.hoverColor;
    } else {
      return widget.numberColor;
    }
  }

  Color colorOfCategory() {
    if (_isHovering) {
      return widget.hoverColor;
    } else if (widget.isSelected) {
      return widget.hoverColor;
    } else {
      return widget.titleColor;
    }
  }
}
