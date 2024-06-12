import 'package:flutter/material.dart';
import 'package:nimbus/api/constants.dart';
import 'package:nimbus/presentation/layout/adaptive.dart';
import 'package:nimbus/presentation/pages/home/sections/projects_section.dart';
import 'package:nimbus/presentation/widgets/content_area.dart';
import 'package:nimbus/presentation/widgets/project_item.dart';
import 'package:nimbus/presentation/widgets/spaces.dart';
import 'package:nimbus/values/values.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Project {
  final int year;
  final String country;
  final double latitude;
  final double longitude;
  final List<String> pictures;
  final String description;
  final int id;
  final String name;

  Project({
    required this.year,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.pictures,
    required this.description,
    required this.id,
    required this.name,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      year: json['year'],
      country: json['country'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      pictures: List<String>.from(json['pictures']),
      description: json['description'],
      id: json['id'],
      name: json['name'],
    );
  }
}

Future<List<Project>?> getProjects({String? country, int? year}) async {
  Map<String, String> queryParams = {};
  String url = "$baseUrl/api/projects";

  if (country != null) {
    queryParams['country'] = country;
  }
  if (year != null) {
    queryParams['year'] = year.toString();
  }

  String queryString = Uri(queryParameters: queryParams).query;
  url = queryString.isNotEmpty ? '$url?$queryString' : url;
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    List<dynamic> body = json.decode(response.body)["projects"];
    List<Project> projects =
        body.map((dynamic item) => Project.fromJson(item)).toList();
    return projects;
  } else {
    return null;
  }
}

class ProjectsPage extends StatefulWidget {
  final String title;
  final String description;

  ProjectsPage({required this.title, required this.description});
  
  @override
  _ProjectsPageState createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> with SingleTickerProviderStateMixin {
  late AnimationController _projectController;
  late Animation<double> _projectScaleAnimation;
  List<Project> projects = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

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

    _fetchProjects();
  }

  @override
  void dispose() {
    _projectController.dispose();
    super.dispose();
  }

  Future<void> _fetchProjects() async {
    setState(() {
      isLoading = true;
    });

    List<Project>? fetchedProjects = await getProjects(year: int.parse(widget.title), country: widget.description);
    if (fetchedProjects != null) {
      setState(() {
        projects = fetchedProjects;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: VisibilityDetector(
        key: Key('project-page'),
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
                child: SingleChildScrollView(
                  child: ContentArea(
                    width: contentAreaWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProjectDescription(),
                        SpaceH40(),
                        isLoading
                          ? CircularProgressIndicator()
                          : Wrap(
                              spacing: kSpacing,
                              runSpacing: kRunSpacing,
                              children: _buildProjects(projects, isMobile: true),
                            ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: getSidePadding(context)),
                      child: ContentArea(
                        width: contentAreaWidth,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ContentArea(
                              width: contentAreaWidth * 0.6,
                              child: _buildProjectDescription(),
                            ),
                            Spacer(),
                          ],
                        ),
                      ),
                    ),
                    SpaceH40(),
                    isLoading
                      ? CircularProgressIndicator()
                      : Container(
                          width: widthOfScreen(context),
                          child: Wrap(
                            spacing: assignWidth(context, 0.025),
                            runSpacing: assignWidth(context, 0.025),
                            children: _buildProjects(projects),
                          ),
                        ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildProjectDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.description,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }

  List<Widget> _buildProjects(List<Project> data, {bool isMobile = false}) {
    List<Widget> items = [];
    for (int index = 0; index < data.length; index++) {
      items.add(
        ScaleTransition(
          scale: _projectScaleAnimation,
          child: ProjectItem(
            width: isMobile
                ? assignWidth(context, 1.0)
                : assignWidth(context, 0.25),
            height: assignHeight(context, 0.2),
            bannerHeight: isMobile
                ? assignHeight(context, 0.1)
                : assignHeight(context, 0.1),
            title: data[index].name,
            subtitle: data[index].country,
            imageUrl: data[index].pictures.isNotEmpty
                ? '$baseUrl/api/storage/${data[index].pictures[0]}'
                : 'assets/images/placeholder.png',
          ),
        ),
      );
    }

    return items;
  }
}
