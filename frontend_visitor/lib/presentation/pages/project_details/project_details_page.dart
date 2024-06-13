import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:auto_route/auto_route.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchProjectDetails();
  }

  void _fetchProjectDetails() async {
    List<Project>? projects = await getProjects();
    if (projects != null) {
      setState(() {
        project = projects.firstWhere((proj) => proj.id == widget.projectId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            context.router.pop();
          },
        ),
        title: Text('Project Details'),
      ),
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
          _buildImageSlider(),
          _buildProjectDetails(),
        ],
      ),
    );
  }

  Widget _buildWebLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildImageSlider(),
        ),
        Expanded(
          flex: 3,
          child: _buildProjectDetails(),
        ),
      ],
    );
  }

  Widget _buildImageSlider() {
    return Container(
      height: 400,
      child: PageView(
        children: project!.pictures.map((picture) {
          return Image.network('$baseUrl/api/storage/$picture', fit: BoxFit.cover);
        }).toList(),
      ),
    );
  }

  Widget _buildProjectDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project!.name,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            project!.description,
            style: TextStyle(fontSize: 18),
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
        ],
      ),
    );
  }
}
