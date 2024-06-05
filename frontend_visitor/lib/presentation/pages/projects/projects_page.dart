import 'package:flutter/material.dart';
import 'package:nimbus/presentation/layout/adaptive.dart';
import 'package:nimbus/presentation/pages/home/sections/projects_section.dart';
import 'package:nimbus/presentation/widgets/content_area.dart';
import 'package:nimbus/presentation/widgets/project_item.dart';
import 'package:nimbus/presentation/widgets/spaces.dart';
import 'package:nimbus/values/values.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:visibility_detector/visibility_detector.dart';

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
  late List<ProjectData> selectedProject;
  List<List<ProjectData>> projects = [
    Data.allProjects,
    Data.branding,
    Data.packaging,
    Data.photograhy,
    Data.webDesign,
  ];

  @override
  void initState() {
    super.initState();
    selectedProject = projects[0];

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

    _projectController.forward();
  }

  @override
  void dispose() {
    _projectController.dispose();
    super.dispose();
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
                        Wrap(
                          spacing: kSpacing,
                          runSpacing: kRunSpacing,
                          children: _buildProjects(selectedProject, isMobile: true),
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
                    Container(
                      width: widthOfScreen(context),
                      child: Wrap(
                        spacing: assignWidth(context, 0.025),
                        runSpacing: assignWidth(context, 0.025),
                        children: _buildProjects(selectedProject),
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

  List<Widget> _buildProjects(List<ProjectData> data, {bool isMobile = false}) {
    List<Widget> items = [];
    for (int index = 0; index < data.length; index++) {
      items.add(
        ScaleTransition(
          scale: _projectScaleAnimation,
          child: ProjectItem(
            width: isMobile
                ? assignWidth(context, data[index].mobileWidth)
                : assignWidth(context, data[index].width),
            height: isMobile
                ? assignHeight(context, data[index].mobileHeight)
                : assignHeight(context, data[index].height),
            bannerHeight: isMobile
                ? assignHeight(context, data[index].mobileHeight) / 2
                : assignHeight(context, data[index].height) / 3,
            title: data[index].title,
            subtitle: data[index].category,
            imageUrl: data[index].projectCoverUrl,
          ),
        ),
      );
    }

    return items;
  }
}
