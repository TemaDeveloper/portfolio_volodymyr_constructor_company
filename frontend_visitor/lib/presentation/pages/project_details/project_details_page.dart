import 'dart:ui_web';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:responsive_builder/responsive_builder.dart';
import 'package:universal_html/html.dart' as html;
import 'project_model.dart';
import 'package:nimbus/api/constants.dart';

class ProjectDetailsPage extends StatefulWidget {
  final int projectId;

  const ProjectDetailsPage({
    Key? key,
    required this.projectId,
  }) : super(key: key);

  @override
  _ProjectDetailsPageState createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  Project? project;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchProjectDetails();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _fetchProjectDetails() async {
    try {
      List<Project>? projects = await getProjects();
      if (projects != null) {
        setState(() {
          project = projects.firstWhere((proj) => proj.id == widget.projectId);
          if (project?.pictures.length == 0) {
            project?.pictures = ["$baseUrl/assets/assets/images/placeholder.png"];
          }
          if (kIsWeb) {
            _registerVideoViewFactories();
          }
        });
      }
    } catch (error) {
      print('Error fetching project details: $error');
    }
  }

  void _registerVideoViewFactories() {
    for (var video in project?.videos ?? []) {
      final videoId = 'videoElement_${video.hashCode}';
      // Register the video element
      print('Registering video element with id: $videoId');
      platformViewRegistry.registerViewFactory(videoId, (int viewId) {
        final videoElement = html.VideoElement()
          ..id = videoId
          ..setAttribute('controls', 'true')
          ..setAttribute('src', '$baseUrl/api/projects/storage/$video')
          ..setAttribute('style',
              'width: 100%; height: 100%; display: block; background-color: black;');
        print('Created video element with id: $videoId');
        return videoElement;
      });
    }
  }

  void _previousImage() {
    if (_pageController.page!.toInt() > 0) {
      _pageController.previousPage(
          duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _nextImage() {
    if (_pageController.page!.toInt() <
        project!.pictures.length + project!.videos.length - 1) {
      _pageController.nextPage(
          duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: project == null
          ? Center(child: CircularProgressIndicator())
          : ResponsiveBuilder(
              builder: (context, sizingInformation) {
                double screenWidth = sizingInformation.screenSize.width;
                return screenWidth < 600
                    ? _buildMobileLayout()
                    : _buildWebLayout();
              },
            ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMediaSlider(),
          _buildProjectDetails(),
        ],
      ),
    );
  }

  Widget _buildWebLayout() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: _buildMediaSlider(),
        ),
        Expanded(
          flex: 2,
          child: _buildProjectDetails(),
        ),
      ],
    );
  }

  Widget _buildMediaSlider() {
    bool isSingleMedia =
        (project!.pictures.length + project!.videos.length) == 1;
    return Padding(
      padding: EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: project!.pictures.length + project!.videos.length,
                itemBuilder: (context, index) {
                  if (index < project!.pictures.length) {
                    return Image.network(
                      '$baseUrl/api/projects/storage/${project!.pictures[index]}',
                    );
                  } else {
                    int videoIndex = index - project!.pictures.length;
                    if (kIsWeb) {
                      final videoId =
                          'videoElement_${project!.videos[videoIndex].hashCode}';
                      print('Rendering HtmlElementView with id: $videoId');
                      return HtmlElementView(viewType: videoId);
                    } else {
                      // Use another method for non-web platforms, e.g., Chewie
                      return Text(
                          "Video not supported in this implementation for non-web platforms.");
                    }
                  }
                },
              ),
              Positioned(
                left: 8.0,
                top: 0,
                bottom: 0,
                child: IconButton(
                  icon: Icon(Icons.arrow_left,
                      color: isSingleMedia ? Colors.grey : Colors.black),
                  onPressed: isSingleMedia ? null : _previousImage,
                ),
              ),
              Positioned(
                right: 8.0,
                top: 0,
                bottom: 0,
                child: IconButton(
                  icon: Icon(Icons.arrow_right,
                      color: isSingleMedia ? Colors.grey : Colors.black),
                  onPressed: isSingleMedia ? null : _nextImage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            project!.name,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Year: ${project!.year}',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Location: ${project!.country}',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.all(8), // Add padding if needed
            child: Column(
              children: [
                Text(
                  'Overview',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  project!.description,
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
