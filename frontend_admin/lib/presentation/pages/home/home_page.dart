import 'dart:convert';
import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nimbus/api/constants.dart';
import 'package:nimbus/presentation/layout/adaptive.dart';
import 'package:nimbus/presentation/pages/home/sections/projects_section.dart';
import 'package:nimbus/presentation/routes/router.gr.dart';
import 'package:nimbus/presentation/widgets/app_drawer.dart';
import 'package:nimbus/presentation/widgets/buttons/nimbus_button.dart';
import 'package:nimbus/presentation/widgets/content_area.dart';
import 'package:nimbus/presentation/widgets/project_item.dart';
import 'package:nimbus/presentation/widgets/spaces.dart';
import 'package:nimbus/values/values.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:nimbus/api/create_project.dart'; 
import 'package:nimbus/api/file_picker_helper.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _projectController;
  late Animation<double> _projectScaleAnimation;
  List<List<ProjectData>> projects = [
    Data.allProjects,
    Data.branding,
    Data.packaging,
    Data.photograhy,
    Data.webDesign,
  ];
  late List<ProjectData> recentlyAddedProjects;
  List<String> years = [];
  bool isLoading = true;

  Uint8List? webImage;
  File? _imageFile;
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _yearController = TextEditingController();
  TextEditingController _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    recentlyAddedProjects = projects[0];

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

    _scrollController.addListener(() {
      if (_scrollController.position.pixels < 100) {
        _controller.reverse();
      }
    });

    _fetchYears();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _projectController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _yearController.dispose();
    _countryController.dispose();
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

  Future<void> _pickImage() async {
    final pickedFile = await pickFile();
    if (pickedFile != null) {
      setState(() {
        webImage = pickedFile.bytes;
        _imageFile = File(pickedFile.name); // Only for the purpose of displaying the image in mobile
      });
    }
  }

  Future<bool> _createProject(CreateProjectRequest project, List<CustomPickedFile> pictures) async {
    final url = "$baseUrl/api/projects";

    // Create multipart request
    final request = http.MultipartRequest('POST', Uri.parse(url));

    // Add JSON data as a field
    request.fields['json'] = json.encode(project.toJson());

    // Add pictures as files
    for (CustomPickedFile picture in pictures) {
      request.files.add(http.MultipartFile.fromBytes(
        'pictures',
        picture.bytes,
        filename: picture.name,
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    // Send the request
    try {
      final response = await request.send();

      // Check the status code
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to upload project: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error uploading project: $e');
      return false;
    }
  }

  Future<void> _addProject() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all the fields')),
      );
      return;
    }

    final project = CreateProjectRequest(
      name: _titleController.text,
      description: _descriptionController.text,
      year: int.parse(_yearController.text),
      geoData: GeoData(country: _countryController.text, latitude: 0, longitude: 0),
    );

    List<CustomPickedFile> pictures = [];
    if (webImage != null) {
      pictures.add(CustomPickedFile(bytes: webImage!, name: 'image.png'));
    }

    bool success = await _createProject(project, pictures);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Project created successfully')),
      );
      // Clear the form
      setState(() {
        _titleController.clear();
        _descriptionController.clear();
        _yearController.clear();
        _countryController.clear();
        _imageFile = null;
        webImage = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create project')),
      );
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
    double screenHeight = heightOfScreen(context);
    double spacerHeight = screenHeight * 0.10;

    return Scaffold(
      key: _scaffoldKey,
      drawer: ResponsiveBuilder(
        refinedBreakpoints: RefinedBreakpoints(),
        builder: (context, sizingInformation) {
          double screenWidth = sizingInformation.screenSize.width;
          if (screenWidth < RefinedBreakpoints().desktopSmall) {
            return AppDrawer(
              menuList: [], // Add your navigation items here
            );
          } else {
            return Container();
          }
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _animation,
        child: FloatingActionButton(
          onPressed: () {
            // Scroll to top section
            _scrollController.animateTo(0,
                duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
          },
          child: Icon(
            FontAwesomeIcons.arrowUp,
            size: Sizes.ICON_SIZE_18,
            color: AppColors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  Stack(
                    children: [
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.center,
                          child: Image.asset(ImagePath.BLOB_BEAN_ASH),
                        ),
                      ),
                      Column(
                        children: [
                          _buildAdminControls(),
                          SizedBox(height: spacerHeight),
                          _buildAddProjectSection(context),
                          SizedBox(height: spacerHeight),
                          _buildProjectsSection(context),
                        ],
                      )
                    ],
                  ),
                  SizedBox(height: spacerHeight),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin Page',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SpaceH20(),
        Text(
          'Generate a temporary link for another user:',
          style: TextStyle(
            fontSize: 16,
          ),
        ),
        SpaceH20(),
        ElevatedButton(
          onPressed: () {
            // Implement link generation logic here
          },
          child: Text('Generate Link'),
        ),
      ],
    );
  }

  Widget _buildAddProjectSection(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Project',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SpaceH20(),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: isMobile(context)
                    ? assignWidth(context, 0.9)
                    : assignWidth(context, 0.5),
                height: isMobile(context)
                    ? assignHeight(context, 0.2)
                    : assignHeight(context, 0.3),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  border: Border.all(
                    color: Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Center(
                  child: webImage != null
                      ? Image.memory(webImage!)
                      : _imageFile != null
                          ? Image.file(_imageFile!)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                                Text(
                                  "Tap to add image",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                ),
              ),
            ),
            SpaceH20(),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Project Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            SpaceH20(),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Project Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            SpaceH20(),
            TextField(
              controller: _yearController,
              decoration: InputDecoration(
                labelText: 'Project Year',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            SpaceH20(),
            TextField(
              controller: _countryController,
              decoration: InputDecoration(
                labelText: 'Project Country',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            SpaceH20(),
            NimbusButton(
              buttonTitle: "Add Project",
              onPressed: _addProject,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsSection(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double contentAreaWidth = screenWidth - (getSidePadding(context) * 2);

    return VisibilityDetector(
      key: Key('project-section'),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNimbusInfoSection(),
                  SpaceH40(),
                  Wrap(
                    spacing: kSpacing,
                    runSpacing: kRunSpacing,
                    children: _buildProjectCategories(years),
                  ),
                  SpaceH40(),
                  Wrap(
                    runSpacing: assignHeight(context, 0.05),
                    children: _buildProjects(
                      recentlyAddedProjects,
                      isMobile: true,
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: getSidePadding(context)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ContentArea(
                        width: contentAreaWidth * 0.6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildNimbusInfoSection(),
                            SpaceH40(),
                            Wrap(
                              spacing: kSpacing,
                              runSpacing: kRunSpacing,
                              children: _buildProjectCategories(years),
                            ),
                          ],
                        ),
                      ),
                      Spacer(),
                    ],
                  ),
                ),
                SpaceH40(),
                Container(
                  width: widthOfScreen(context),
                  child: Wrap(
                    spacing: assignWidth(context, 0.025),
                    runSpacing: assignWidth(context, 0.025),
                    children: _buildProjects(recentlyAddedProjects),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  List<Widget> _buildProjectCategories(List<String> years) {
    List<Widget> items = [];

    for (int index = 0; index < years.length; index++) {
      items.add(
        ProjectCategory(
          title: years[index],
          number: index + 1,
          isSelected: false,
          onTap: () => onProjectCategoryTap(index),
        ),
      );
    }
    return items;
  }

  void onProjectCategoryTap(int index) {
    _projectController.reset();
    changeCategorySelected(index);
    setState(() {
      recentlyAddedProjects = projects[index];
      _playProjectAnimation();
    });
  }

  void changeCategorySelected(int selectedIndex) {
    setState(() {
      for (int index = 0; index < years.length; index++) {
        // Ensure the selection logic works based on your specific requirements
      }
    });
  }

  List<Widget> _buildProjects(List<ProjectData> data, {bool isMobile = false}) {
    List<Widget> items = [];
    for (int index = 0; index < data.length; index++) {
      items.add(
        GestureDetector(
          onTap: () {
            context.router.push(UpgradeProjectRoute(
              title: data[index].title,
              description: data[index].category,
            ));
          },
          child: ScaleTransition(
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
        ),
      );
    }

    return items;
  }

  Widget _buildNimbusInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recently Added Projects',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SpaceH20(),
        Text(
          'A collection of projects recently added by users.',
          style: TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  bool isMobile(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return width < RefinedBreakpoints().tabletLarge;
  }
}

Future<List<String>?> getYears() async {
  final response = await http.get(Uri.parse('$baseUrl/years'));

  if (response.statusCode == 200) {
    Map<String, dynamic> jsonResponse = json.decode(response.body);
    return List<String>.from(jsonResponse['years']);
  } else {
    return null;
  }
}
