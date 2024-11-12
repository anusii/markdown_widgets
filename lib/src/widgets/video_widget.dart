/// Video playback widget.
///
// Time-stamp: <Tuesday 2024-11-12 20:18:13 +1100 Graham Williams>
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

import 'package:flutter/material.dart';

import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';

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
  bool _isVideoInitialized = false;

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

    // Load asset data.

    ByteData bytes = await rootBundle.load(videoAssetPath);

    // Get temporary directory.

    String dir = (await getTemporaryDirectory()).path;

    // Create a file in the temporary directory.

    File tempVideo = File('$dir/${widget.filename}');

    // Write bytes to file.

    await tempVideo.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

    // Initialise the player.

    _player = Player();
    _controller = VideoController(_player);

    // Open the video file but do not autoplay.

    await _player.open(Media(tempVideo.path), play: false);

    // Set video initialised.

    setState(() {
      _isVideoInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideoInitialized) {
      return _buildVideoPlayer();
    } else {
      return Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildVideoPlayer() {
    return Center(
      child: FractionallySizedBox(
        widthFactor: contentWidthFactor,
        child: AspectRatio(
          // Default aspect ratio
          aspectRatio: 16 / 9,
          child: Focus(
            canRequestFocus: false,
            child: Video(controller: _controller),
          ),
        ),
      ),
    );
  }
}
