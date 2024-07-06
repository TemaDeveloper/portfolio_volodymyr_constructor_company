import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FullScreenMedia extends StatelessWidget {
  final String mediaUrl;
  final bool isVideo;

  FullScreenMedia({required this.mediaUrl, this.isVideo = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: isVideo
            ? (kIsWeb
                ? HtmlElementView(viewType: mediaUrl)
                : Text("Video not supported in this implementation for non-web platforms."))
            : Image.network(mediaUrl),
      ),
    );
  }
}
