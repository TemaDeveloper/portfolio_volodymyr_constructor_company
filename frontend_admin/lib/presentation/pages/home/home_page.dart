import 'dart:convert';
import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nimbus/api/auth.dart';
import 'package:nimbus/api/constants.dart';
import 'package:nimbus/api/list_projects.dart';
import 'package:nimbus/api/upload.dart';
import 'package:nimbus/api/years.dart';
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
  List<Project> projects = [];
  List<String> years = [];
  bool isLoading = true;
  int? selectedYear;

  final List<String> timeIntervals = [
    '1 hour',
    '2 hours',
    '3 hours',
    '5 hours',
    '8 hours',
    '24 hours',
    '48 hours',
  ];

  double _currentSliderValue = 0;

  Uint8List? webImage;
  File? _imageFile;
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _yearController = TextEditingController();
  TextEditingController _countryController = TextEditingController();
  List<XFile> _mediaFiles = [];

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

    _projectController.forward();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels < 100) {
        _controller.reverse();
      }
    });

    _fetchYears();
    _fetchProjects();
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

  Future<void> _fetchProjects({int? year}) async {
    setState(() {
      isLoading = true;
    });
    List<Project>? fetchedProjects = await getProjects(year: year);
    if (fetchedProjects != null) {
      setState(() {
        projects = fetchedProjects;
        isLoading = false;
      });
    } else {
      // Handle error
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _generateLink() async {
    setState(() {
      isLoading = true;
    });

    int validFor;
    switch (_currentSliderValue.toInt()) {
      case 0:
        validFor = 1 * 3600;
        break;
      case 1:
        validFor = 2 * 3600;
        break;
      case 2:
        validFor = 3 * 3600;
        break;
      case 3:
        validFor = 5 * 3600;
        break;
      case 4:
        validFor = 8 * 3600;
        break;
      case 5:
        validFor = 24 * 3600;
        break;
      case 6:
        validFor = 48 * 3600;
        break;
      default:
        validFor = 1 * 3600;
    }

    try {
      String link = await issueVisitorLink(validFor: validFor);
      print(link);
      await Clipboard.setData(ClipboardData(text: link));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Link copied to clipboard: $link')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate link: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  void _showMediaPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.image),
            title: Text('Pick Images'),
            onTap: () async {
              Navigator.pop(context);
              final List<XFile>? pickedFiles = await ImagePicker().pickMultiImage();
              if (pickedFiles != null) {
                setState(() {
                  _mediaFiles.addAll(pickedFiles);
                });
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.video_library),
            title: Text('Pick Video'),
            onTap: () async {
              Navigator.pop(context);
              final XFile? pickedVideo = await ImagePicker().pickVideo(source: ImageSource.gallery);
              if (pickedVideo != null) {
                setState(() {
                  _mediaFiles.add(pickedVideo);
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Future<CustomPickedFile> convertXFileToCustomPickedFile(XFile file) async {
  return CustomPickedFile(
    name: file.name,
    bytes: await file.readAsBytes(),
  );
}


  Future<void> _addProject() async {
  if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please fill all the fields')),
    );
    return;
  }

  final List<CustomPickedFile> pictures = [];
  final List<CustomPickedFile> videos = [];

  for (XFile file in _mediaFiles) {
    if (file.mimeType?.startsWith('image/') ?? false) {
      pictures.add(await convertXFileToCustomPickedFile(file));
    } else if (file.mimeType?.startsWith('video/') ?? false) {
      videos.add(await convertXFileToCustomPickedFile(file));
    }
  }

  final project = CreateProjectRequest(
    name: _titleController.text,
    description: _descriptionController.text,
    year: int.tryParse(_yearController.text),
    geoData: GeoData(
      country: _countryController.text,
      latitude: 0.0, // Replace with actual latitude
      longitude: 0.0, // Replace with actual longitude
    ),
  );

  ProjectResponse? response = await createProject(project, pictures, videos);

  if (response != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Project created successfully')),
    );
    // Clear the form
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _yearController.clear();
      _countryController.clear();
      _mediaFiles.clear();
    });
    _fetchProjects();
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
        
        Column(
          children: [
            Slider(
              value: _currentSliderValue,
              min: 0,
              max: (timeIntervals.length - 1).toDouble(),
              divisions: timeIntervals.length - 1,
              label: timeIntervals[_currentSliderValue.toInt()],
              onChanged: (double value) {
                setState(() {
                  _currentSliderValue = value;
                });
              },
            ),
            SizedBox(height: 16),
            Text(
              'Selected Time: ${timeIntervals[_currentSliderValue.toInt()]}',
              style: TextStyle(fontSize: 18),
            ),
            SpaceW20(),
        NimbusButton(
          buttonTitle: "Generate Link",
          onPressed: _generateLink,
          
        ),
          ],
        )
      ],
    );
  }

  Widget _buildAddProjectSection(BuildContext context) {
  return Card(
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
          InkWell(
            onTap: () => _showMediaPickerOptions(context),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      size: 50,
                      color: Colors.grey,
                    ),
                    Text(
                      "Tap to add media",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SpaceH20(),
          if (_mediaFiles.isNotEmpty) _buildSelectedMedia(),
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

Widget _buildSelectedMedia() {
  return Column(
    children: _mediaFiles.map((media) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            if (media.mimeType?.startsWith('image/') ?? false)
              if (kIsWeb)
                Image.network(
                  media.path,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                )
              else
                Image.file(
                  File(media.path),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                )
            else if (media.mimeType?.startsWith('video/') ?? false)
              Container(
                width: 100,
                height: 100,
                child: Icon(Icons.videocam, size: 50),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                media.name,
                style: TextStyle(
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  _mediaFiles.remove(media);
                });
              },
            ),
          ],
        ),
      );
    }).toList(),
  );
}

Future<void> _uploadSelectedMedia() async {
  final images = _mediaFiles
      .where((file) => file.mimeType?.startsWith('image/') ?? false)
      .map((file) => MultipartFile.fromFileSync(file.path, filename: file.name))
      .toList();

  final videos = _mediaFiles
      .where((file) => file.mimeType?.startsWith('video/') ?? false)
      .map((file) => MultipartFile.fromFileSync(file.path, filename: file.name))
      .toList();

  try {
    if (images.isNotEmpty) {
      await uploadPictures(images);
    }
    if (videos.isNotEmpty) {
      await uploadVideos(videos);
    }
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Media uploaded successfully')));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload some media')));
  }
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
              padding:
                  EdgeInsets.symmetric(horizontal: getSidePadding(context)),
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
                      projects,
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
                  padding:
                      EdgeInsets.symmetric(horizontal: getSidePadding(context)),
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
                    children: _buildProjects(projects),
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
          isSelected: selectedYear == int.parse(years[index]),
          onTap: () => onProjectCategoryTap(int.parse(years[index])),
        ),
      );
    }
    return items;
  }

  void onProjectCategoryTap(int year) {
    setState(() {
      selectedYear = year;
      _fetchProjects(year: year);
    });
  }

  List<Widget> _buildProjects(List<Project> projects, {bool isMobile = false}) {
    List<Widget> items = [];
    for (int index = 0; index < projects.length; index++) {
      items.add(
        GestureDetector(
          onTap: () {
            context.router.push(UpgradeProjectRoute(
              title: projects[index].name,
              description: projects[index].description,
              year: projects[index].year.toString(),
              country: projects[index].country,
              id: projects[index].id,
              initialMediaUrls: projects[index].pictures
            ));
          },
          child: ScaleTransition(
            scale: _projectScaleAnimation,
            child: ProjectItem(
              width: isMobile
                  ? assignWidth(context, 300)
                  : assignWidth(context, 400),
              height: isMobile
                  ? assignHeight(context, 300)
                  : assignHeight(context, 400),
              bannerHeight: isMobile
                  ? assignHeight(context, 150)
                  : assignHeight(context, 200),
              title: projects[index].name,
              subtitle: projects[index].country,
              imageUrl: projects[index].pictures.isNotEmpty
                  ? '$baseUrl/api/projects/storage/${projects[index].pictures[0]}'
                  : 'assets/images/placeholder.png',
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

