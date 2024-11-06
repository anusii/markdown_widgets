/// Video playback widget.
///
// Time-stamp: <Sunday 2023-12-31 18:58:28 +1100 Graham Williams>
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
///
/// Licensed under the MIT License (the "License").
///
/// License: https://choosealicense.com/licenses/mit/.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
///
/// Authors: Tony Chen

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:markdown_widgets/src/constants/pkg.dart'
    show contentWidthFactor, mediaPath;

class VideoWidget extends StatefulWidget {
  final String filename;

  const VideoWidget({Key? key, required this.filename}) : super(key: key);

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  late final Player _player;
  late final VideoController _controller;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    final String videoAssetPath = '$mediaPath/${widget.filename}';

    // Load asset data
    ByteData bytes = await rootBundle.load(videoAssetPath);

    // Get the temporary directory
    String dir = (await getTemporaryDirectory()).path;

    // Create a file in the temporary directory
    File tempVideo = File('$dir/${widget.filename}');

    // Write bytes to the file
    await tempVideo.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

    // Initialise the player
    _player = Player();
    _controller = VideoController(_player);

    // Open the video file from the temporary directory
    await _player.open(Media(tempVideo.path));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeVideo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return _buildVideoPlayer();
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildVideoPlayer() {
    return Center(
      child: FractionallySizedBox(
        widthFactor: contentWidthFactor,
        child: AspectRatio(
          aspectRatio: 16 / 9, // Default aspect ratio
          child: Video(controller: _controller),
        ),
      ),
    );
  }
}
