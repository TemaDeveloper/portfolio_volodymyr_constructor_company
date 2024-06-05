import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nimbus/presentation/layout/adaptive.dart';
import 'package:nimbus/presentation/widgets/buttons/nimbus_button.dart';
import 'package:nimbus/presentation/widgets/spaces.dart';
import 'package:nimbus/values/values.dart';
import 'package:responsive_builder/responsive_builder.dart';

class UpgradeProjectPage extends StatefulWidget {
  final String title;
  final String description;

  UpgradeProjectPage({
    required this.title,
    required this.description,
  });

  @override
  _UpgradeProjectPageState createState() => _UpgradeProjectPageState();
}

class _UpgradeProjectPageState extends State<UpgradeProjectPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  List<XFile> _images = [];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.title;
    _descriptionController.text = widget.description;
  }

  Future<void> _pickImages() async {
    final ImagePicker _picker = ImagePicker();
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _images.addAll(pickedFiles);
      });
    }
  }

  bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < RefinedBreakpoints().tabletLarge;
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
                if (_images.isNotEmpty) _buildSelectedImages(),
                SpaceH20(),
                NimbusButton(
                  buttonTitle: 'Update',
                  onPressed: () {
                    // Handle the update logic here
                  },
                ),
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

  Widget _buildImagePlaceholder(BuildContext context) {
    return InkWell(
      onTap: _pickImages,
      child: Container(
        width: isMobile(context) ? assignWidth(context, 0.9) : assignWidth(context, 0.5),
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

  Widget _buildSelectedImages() {
    return Column(
      children: _images.map((image) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              if (kIsWeb)
                Image.network(
                  image.path,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                )
              else
                Image.file(
                  File(image.path),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  image.name,
                  style: TextStyle(
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
