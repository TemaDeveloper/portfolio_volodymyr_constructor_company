import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'package:flutter/material.dart';

class VideoComponent extends StatelessWidget {
  const VideoComponent({
    required this.id,
    required this.bytes,
    required this.mimeType,
  });

  // unique id
  final String id;

  // mimetype like video/mp4, video/webm
  final String mimeType;

  // video data
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    final sourceElement = html.SourceElement();
    sourceElement.type = mimeType;
    sourceElement.src = Uri.dataFromBytes(bytes, mimeType: mimeType).toString();

    final videoElement = html.VideoElement();
    videoElement.controls = true;
    videoElement.children = [sourceElement];
    videoElement.style.height = '100%';
    videoElement.style.width = '100%';

    ui_web.platformViewRegistry.registerViewFactory(id, (int viewId) => videoElement);

    return HtmlElementView(viewType: id);
  }
}
