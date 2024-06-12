import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nimbus/api/delete.dart';
import 'package:nimbus/api/update.dart';
import 'package:nimbus/presentation/layout/adaptive.dart';
import 'package:nimbus/presentation/widgets/buttons/nimbus_button.dart';
import 'package:nimbus/presentation/widgets/spaces.dart';
import 'package:nimbus/values/values.dart';
import 'package:responsive_builder/responsive_builder.dart';

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

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.title;
    _descriptionController.text = widget.description;
    _yearController.text = widget.year;
    _locationController.text = widget.country;
  }

  Future<void> _pickMedia(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    final XFile? pickedVideo = await _picker.pickVideo(source: source);

    if (pickedFiles != null) {
      setState(() {
        _mediaFiles.addAll(pickedFiles);
      });
    }

    if (pickedVideo != null) {
      setState(() {
        _mediaFiles.add(pickedVideo);
      });
    }
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
                Text(
                  'Upgrade Project',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SpaceH20(),
                _buildTextField(_titleController, 'Title'),
                SpaceH20(),
                _buildTextField(_descriptionController, 'Description'),
                SpaceH20(),
                _buildTextField(_locationController, 'Location'),
                SpaceH20(),
                _buildTextField(_yearController, 'Year'),
                SpaceH20(),
                _buildImagePlaceholder(context),
                SpaceH20(),
                if (_mediaFiles.isNotEmpty) _buildSelectedMedia(),
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

  void _updateProject() async {
    final int projectId = widget.id;

    final updateRequest = UpdateProjectRequest(
      name: _titleController.text.isNotEmpty ? _titleController.text : null,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      year: _yearController.text.isNotEmpty ? int.tryParse(_yearController.text) : null,
      country: _locationController.text.isNotEmpty ? _locationController.text : null,
    );

    final success = await updateProject(projectId, updateRequest);

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

  Widget _buildImagePlaceholder(BuildContext context) {
    return InkWell(
      onTap: () => _showMediaPickerOptions(context),
      child: Container(
        width: isMobile(context) ? assignWidth(context, 0.9) : assignWidth(context, 0.9),
        height: isMobile(context) ? assignHeight(context, 0.2) : assignHeight(context, 0.3),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: Colors.grey,
            width: 2.0,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.add_a_photo,
            size: 50,
            color: Colors.grey,
          ),
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
}
