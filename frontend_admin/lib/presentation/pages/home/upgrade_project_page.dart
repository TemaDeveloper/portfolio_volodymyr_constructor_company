import 'dart:io';
import 'dart:ui_web';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nimbus/api/constants.dart';
import 'package:nimbus/api/delete.dart';
import 'package:nimbus/api/delete_file.dart';
import 'package:nimbus/api/project_model.dart';
import 'package:nimbus/api/update.dart';
import 'package:nimbus/api/upload.dart';
import 'package:nimbus/presentation/layout/adaptive.dart';
import 'package:nimbus/presentation/widgets/buttons/nimbus_button.dart';
import 'package:nimbus/presentation/widgets/spaces.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:universal_html/html.dart' as html;

class CustomPickedFile {
  final String name;
  final List<int> bytes;

  CustomPickedFile({
    required this.name,
    required this.bytes,
  });
}

class UpgradeProjectPage extends StatefulWidget {
  final String title;
  final String description;
  final String year;
  final String country;
  final int id;

  UpgradeProjectPage({
    required this.title,
    required this.description,
    required this.year,
    required this.country,
    required this.id,
  });

  @override
  _UpgradeProjectPageState createState() => _UpgradeProjectPageState();
}

class _UpgradeProjectPageState extends State<UpgradeProjectPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  List<XFile> _mediaFiles = [];
  List<String> _mediaToDelete = [];
  Project? project;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.title;
    _descriptionController.text = widget.description;
    _yearController.text = widget.year;
    _locationController.text = widget.country;
    _fetchProjectDetails();
  }

  void _fetchProjectDetails() async {
    try {
      List<Project>? projects = await getProjects();
      if (projects != null) {
        setState(() {
          project = projects.firstWhere((proj) => proj.id == widget.id);
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
      platformViewRegistry.registerViewFactory(videoId, (int viewId) {
        final videoElement = html.VideoElement()
          ..id = videoId
          ..setAttribute('controls', 'true')
          ..setAttribute('src', '$baseUrl/api/projects/storage/$video')
          ..setAttribute('style', 'width: 100%; height: 100%; display: block; background-color: black;');
        return videoElement;
      });
    }
  }

  void _markMediaForDeletion(int index) {
    setState(() {
      if (index < project!.pictures.length) {
        _mediaToDelete.add(project!.pictures[index]);
        project!.pictures.removeAt(index);
      } else {
        int videoIndex = index - project!.pictures.length;
        _mediaToDelete.add(project!.videos[videoIndex]);
        project!.videos.removeAt(videoIndex);
      }
    });
  }

  Widget _buildMediaList() {
    if (project == null) {
      return Center(child: CircularProgressIndicator());
    }

    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: project!.pictures.length + project!.videos.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.all(8.0),
                  width: 150,
                  height: 200,
                  child: IconButton(
                    icon: Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                    onPressed: () => _showMediaPickerOptions(context),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: Colors.grey,
                      width: 2.0,
                    ),
                  ),
                ),
              ],
            );
          }

          if (index - 1 < project!.pictures.length) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.all(8.0),
                  width: 150,
                  height: 200,
                  child: Image.network(
                    '$baseUrl/api/projects/storage/${project!.pictures[index - 1]}',
                    fit: BoxFit.cover,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _markMediaForDeletion(index - 1),
                ),
              ],
            );
          } else {
            int videoIndex = index - 1 - project!.pictures.length;
            if (kIsWeb) {
              final videoId = 'videoElement_${project!.videos[videoIndex].hashCode}';
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.all(8.0),
                    width: 150,
                    height: 200,
                    child: HtmlElementView(viewType: videoId),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _markMediaForDeletion(index - 1),
                  ),
                ],
              );
            } else {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.all(8.0),
                    width: 150,
                    height: 200,
                    color: Colors.black12,
                    child: Center(child: Text("Video not supported")),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _markMediaForDeletion(index - 1),
                  ),
                ],
              );
            }
          }
        },
      ),
    );
  }

  Future<MultipartFile> convertXFileToMultipartFile(XFile file) async {
    return MultipartFile.fromBytes(await file.readAsBytes(), filename: file.name);
  }

  bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < RefinedBreakpoints().tabletLarge;
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
              final ImagePicker _picker = ImagePicker();
              final List<XFile>? pickedFiles = await _picker.pickMultiImage();
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
              final ImagePicker _picker = ImagePicker();
              final XFile? pickedVideo = await _picker.pickVideo(source: ImageSource.gallery);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upgrade Project'),
      ),
      body: ResponsiveBuilder(
        builder: (context, sizingInformation) {
          double screenWidth = sizingInformation.screenSize.width;
          double contentAreaWidth = screenWidth - (getSidePadding(context) * 2);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: getSidePadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMediaList(),
                SpaceH20(),
                if (_mediaFiles.isNotEmpty) _buildSelectedMedia(),
                SpaceH20(),
                _buildTextField(_titleController, 'Title'),
                SpaceH20(),
                _buildTextField(_descriptionController, 'Description'),
                SpaceH20(),
                _buildTextField(_locationController, 'Location'),
                SpaceH20(),
                _buildTextField(_yearController, 'Year'),
                SpaceH20(),
                Row(
                  children: [
                    NimbusButton(
                      buttonTitle: 'Update',
                      onPressed: _updateProject,
                    ),
                    SpaceW12(),
                    NimbusButton(
                      buttonTitle: 'Delete',
                      onPressed: _deleteProject,
                    ),
                  ],
                ),
                SpaceH16()
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }

  Future<void> _updateProject() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all the fields')),
      );
      return;
    }

    // Step 1: Delete existing media marked for deletion
    for (String media in _mediaToDelete) {
      await deleteFile(media);
    }

    final List<MultipartFile> pictureFiles = [];
    final List<MultipartFile> videoFiles = [];

    // Step 2: Convert new media files (XFile) to MultipartFile
    for (XFile file in _mediaFiles) {
      if (file.mimeType?.startsWith('image/') ?? false) {
        pictureFiles.add(await convertXFileToMultipartFile(file));
      } else if (file.mimeType?.startsWith('video/') ?? false) {
        videoFiles.add(await convertXFileToMultipartFile(file));
      }
    }

    // Upload new pictures and videos and get their file IDs
    List<String> newPictureIds = await uploadPictures(pictureFiles);
    List<String> newVideoIds = await uploadVideos(videoFiles);

    // Combine new and existing media names
    List<String> updatedPictures = project!.pictures + newPictureIds;
    List<String> updatedVideos = project!.videos + newVideoIds;

    // Step 3: Prepare the update request with new info and media lists
    final updateRequest = UpdateProjectRequest(
      name: _titleController.text.isNotEmpty ? _titleController.text : null,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      year: _yearController.text.isNotEmpty ? int.tryParse(_yearController.text) : null,
      country: _locationController.text.isNotEmpty ? _locationController.text : null,
      pictures: updatedPictures,
      videos: updatedVideos,
    );

    // Step 4: Send the update project request
    final success = await updateProject(widget.id, updateRequest);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Project is updated successfully')),
      );
      print('Project updated successfully');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Project is not updated')),
      );
      print('Failed to update project');
    }
  }

  void _deleteProject() async {
    final projectId = widget.id;
    final success = await deleteProject(projectId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Project is deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Project is not deleted')),
      );
    }
  }

  Widget _buildSelectedMedia() {
    return Column(
      children: _mediaFiles.map((media) {
        return Stack(
          children: [
            Padding(
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
            ),
            Positioned(
              right: 8,
              top: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _mediaFiles.remove(media);
                  });
                },
                child: Icon(Icons.cancel, color: Colors.red),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
