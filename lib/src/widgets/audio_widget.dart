/// Audio playback widget.
///
// Time-stamp: <Tuesday 2024-11-12 20:23:32 +1100 Graham Williams>
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

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:audioplayers/audioplayers.dart';

import 'package:markdown_widget_builder/src/constants/pkg.dart'
    show contentWidthFactor, mediaPath;

class AudioWidget extends StatefulWidget {
  final String filename;

  const AudioWidget({Key? key, required this.filename}) : super(key: key);

  @override
  _AudioWidgetState createState() => _AudioWidgetState();
}

class _AudioWidgetState extends State<AudioWidget> {
  late AudioPlayer _player;
  Duration? _duration;
  Duration _position = Duration.zero;
  PlayerState? _playerState;

  // Declare the StreamSubscription variables.

  late StreamSubscription<Duration> _durationSubscription;
  late StreamSubscription<Duration> _positionSubscription;
  late StreamSubscription<PlayerState> _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    _initAudioPlayer();
  }

  void _initAudioPlayer() async {
    // Build the raw path from mediaPath + filename.

    final String rawLocalPath = '$mediaPath/${widget.filename}';

    // If rawLocalPath has 'file://', parse it to pure local path;
    // otherwise use rawLocalPath as is.

    String localPath;
    if (rawLocalPath.startsWith('file://')) {
      localPath = Uri.parse(rawLocalPath).toFilePath();
    } else {
      localPath = rawLocalPath;
    }

    await _player.setSource(
      DeviceFileSource(localPath),
    );

    // Listen for audio duration.

    _durationSubscription = _player.onDurationChanged.listen((Duration d) {
      if (mounted) {
        setState(() {
          _duration = d;
        });
      }
    });

    // Listen for audio position.

    _positionSubscription = _player.onPositionChanged.listen((Duration p) {
      if (mounted) {
        setState(() {
          _position = p;
        });
      }
    });

    // Listen for player state changes.

    _playerStateSubscription =
        _player.onPlayerStateChanged.listen((PlayerState s) {
      if (mounted) {
        setState(() {
          _playerState = s;
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel the subscriptions.

    _durationSubscription.cancel();
    _positionSubscription.cancel();
    _playerStateSubscription.cancel();

    // Dispose the audio player.

    _player.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _playerState == PlayerState.playing;

    return Center(
      child: FractionallySizedBox(
        widthFactor: contentWidthFactor,
        child: Column(
          children: [
            // Progress bar.

            Slider(
              value: _position.inMilliseconds.toDouble(),
              min: 0.0,
              max: (_duration?.inMilliseconds ?? 0).toDouble(),
              onChanged: (double value) {
                final newPosition = Duration(milliseconds: value.toInt());
                _player.seek(newPosition);
              },
            ),

            // Button row.

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Play/pause button.

                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  onPressed: () {
                    if (isPlaying) {
                      _player.pause();
                    } else {
                      _player.resume();
                    }
                  },
                ),

                // Stop button.

                IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: () {
                    _player.stop();
                    setState(() {
                      _position = Duration.zero;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
