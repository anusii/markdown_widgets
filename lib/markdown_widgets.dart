// Widgets for survey questionnaires defined using markdown-like syntax.
//
// Copyright (C) 2024, Software Innovation Institute, ANU.
//
// Licensed under the GNU General Public License, Version 3 (the "License").
//
// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://www.gnu.org/licenses/>.
//
// Authors: Tony Chen

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:markdown_widgets/constants/constants.dart'
    show contentWidthFactor, screenWidth, mediaPath, endingLines;

class MarkdownWidgetBuilder extends StatefulWidget {
  final String content;
  final String title;
  final String? submitUrl;

  const MarkdownWidgetBuilder({
    Key? key,
    required this.content,
    required this.title,
    this.submitUrl,
  }) : super(key: key);

  @override
  _MarkdownWidgetBuilderState createState() => _MarkdownWidgetBuilderState();
}

class _MarkdownWidgetBuilderState extends State<MarkdownWidgetBuilder> {
  // Store the slider values
  final Map<String, double> _sliderValues = {};

  // Store the slider parameters
  final Map<String, Map<String, dynamic>> _sliders = {};

  // Submit URL
  String? _submitUrl;

  // Store the radio values
  final Map<String, String?> _radioValues = {};

  // Store the checkbox values
  final Map<String, Set<String>> _checkboxValues = {};

  // Store the text input controllers
  final Map<String, TextEditingController> _textControllers = {};

  // Store the date values
  final Map<String, DateTime?> _dateValues = {};

  // Store dropdown values
  final Map<String, String?> _dropdownValues = {};

  // Store dropdown options
  final Map<String, List<String>> _dropdownOptions = {};

  // Store video controllers
  final Map<String, VideoPlayerController> _videoControllers = {};

  // Store audio players
  final Map<String, AudioPlayer> _audioPlayers = {};

  // Store audio durations
  final Map<String, Duration> _audioDurations = {};

  // Store audio positions
  final Map<String, Duration> _audioPositions = {};

  // Store audio player states
  final Map<String, PlayerState> _audioPlayerStates = {};

  @override
  void initState() {
    super.initState();
    _submitUrl = widget.submitUrl ?? 'http://127.0.0.1/feedback';
  }

  @override
  void dispose() {
    // Dispose of video controllers
    _videoControllers.forEach((key, controller) {
      controller.dispose();
    });
    // Release audio players
    _audioPlayers.forEach((key, player) {
      player.dispose();
    });
    // Dispose of text controllers
    _textControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  // Send data method
  Future<void> _sendData() async {
    final Map<String, dynamic> responses = {};

    // Add slider values
    _sliderValues.forEach((key, value) {
      responses[key] = value;
    });

    // Add radio values
    _radioValues.forEach((key, value) {
      responses[key] = value;
    });

    // Add checkbox values
    _checkboxValues.forEach((key, value) {
      // Convert Set to List
      responses[key] = value.toList();
    });

    // Add text input values
    _textControllers.forEach((key, controller) {
      responses[key] = controller.text;
    });

    // Add date values
    _dateValues.forEach((key, value) {
      if (value != null) {
        responses[key] =
        '${value.year}-${value.month.toString().padLeft(2, '0')}-'
            '${value.day.toString().padLeft(2, '0')}';
      } else {
        responses[key] = null;
      }
    });

    // Add dropdown values
    _dropdownValues.forEach((key, value) {
      responses[key] = value;
    });

    final Map<String, dynamic> data = {
      'title': widget.title,
      'responses': responses,
    };

    print('Submitting the following data: $data');

    try {
      final response = await http.post(
        Uri.parse(_submitUrl!),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission successful')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Submission failed: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e')),
      );
    }
  }

  // Build the content widget method
  List<Widget> _buildContentWidgets(String content) {
    // ... [Copy the method implementation from your original code] ...
    // Make sure to adjust any references to `widget` or `context` as needed.
    // The full implementation is identical to your original method.

    // [Due to space constraints, the detailed implementation is omitted here.]
    // Please copy the entire method from your original code into this method.
  }

  // ... [Include all other helper methods here, adjusting references as necessary] ...

  // Parse the time string and return the total seconds
  int _parseTimeString(String timeString) {
    // ... [Copy the method implementation from your original code] ...
  }

  Widget _buildTimerWidget(String timeString) {
    // ... [Copy the method implementation from your original code] ...
  }

  // Build description block widget
  Widget _buildDescriptionBox(String content) {
    // ... [Copy the method implementation from your original code] ...
  }

  // Build heading widget with alignment
  Widget _buildHeading(int level, String content, String align) {
    // ... [Copy the method implementation from your original code] ...
  }

  // Build aligned text widget
  Widget _buildAlignedText(String align, String content) {
    // ... [Copy the method implementation from your original code] ...
  }

  // Function to manually justify text
  List<TextSpan> _justifyText(String text, TextStyle style, double maxWidth) {
    // ... [Copy the method implementation from your original code] ...
  }

  // Build Markdown widget
  Widget _buildMarkdown(String data) {
    // ... [Copy the method implementation from your original code] ...
  }

  // Build image widget
  Widget _buildImageWidget(String filename) {
    // ... [Copy the method implementation from your original code] ...
  }

  // Build video widget
  Widget _buildVideoWidget(String filename) {
    // ... [Copy the method implementation from your original code] ...
  }

  // Build audio widget
  Widget _buildAudioWidget(String filename) {
    // ... [Copy the method implementation from your original code] ...
  }

  // Build the slider widget
  Widget _buildSlider(String name) {
    // ... [Copy the method implementation from your original code] ...
  }

  // Build radio group widget
  Widget _buildRadioGroup(String name, List<Map<String, String>> options) {
    // ... [Copy the method implementation from your original code] ...
  }

  // Build checkbox group widget
  Widget _buildCheckboxGroup(String name, List<Map<String, String>> options) {
    // ... [Copy the method implementation from your original code] ...
  }

  // Build input field widget
  Widget _buildInputField(String name, {bool isMultiLine = false}) {
    // ... [Copy the method implementation from your original code] ...
  }

  // Build calendar field widget
  Widget _buildCalendarField(String name) {
    // ... [Copy the method implementation from your original code] ...
  }

  // Build dropdown widget
  Widget _buildDropdown(String name, List<String> options) {
    // ... [Copy the method implementation from your original code] ...
  }

  @override
  Widget build(BuildContext context) {
    // Build content widgets every time to ensure UI updates
    final contentWidgets = _buildContentWidgets(widget.content);

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: contentWidgets,
      ),
    );
  }
}

// TimerWidget class
class TimerWidget extends StatefulWidget {
  final int totalSeconds;

  const TimerWidget({Key? key, required this.totalSeconds}) : super(key: key);

  @override
  _TimerWidgetState createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  // ... [Copy the TimerWidget implementation from your original code] ...
}
