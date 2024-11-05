/// Markdown widget builder.
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

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:markdown_widgets/src/utils/command_parser.dart';
import 'package:markdown_widgets/src/widgets/input_field.dart';

class MarkdownWidgetBuilder extends StatefulWidget {
  final String content;
  final String title;
  final String? submitUrl;

  final void Function(String title, String content)? onMenuItemSelected;

  const MarkdownWidgetBuilder({
    Key? key,
    required this.content,
    required this.title,
    this.submitUrl,
    this.onMenuItemSelected,
  }) : super(key: key);

  @override
  _MarkdownWidgetBuilderState createState() => _MarkdownWidgetBuilderState();
}

class _MarkdownWidgetBuilderState extends State<MarkdownWidgetBuilder> {
  // Submit URL
  String? _submitUrl;

  // Store the input values
  final Map<String, String> _inputValues = {};

  // Store the slider values
  final Map<String, double> _sliderValues = {};

  // Store the slider parameters
  final Map<String, Map<String, dynamic>> _sliders = {};

  // Store the radio values
  final Map<String, String?> _radioValues = {};

  // Store the checkbox values
  final Map<String, Set<String>> _checkboxValues = {};

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

  final Map<String, GlobalKey<InputFieldState>> _inputFieldKeys = {};

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

    // Add text input values
    _inputValues.forEach((key, value) {
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

  List<Widget> _buildContentWidgets(String content) {
    final parser = CommandParser(
      context: context,
      content: content,
      fullContent: widget.content,
      onMenuItemSelected: widget.onMenuItemSelected,
      state: {
        '_inputValues': _inputValues,
        '_sliderValues': _sliderValues,
        '_sliders': _sliders,
        '_radioValues': _radioValues,
        '_checkboxValues': _checkboxValues,
        '_dateValues': _dateValues,
        '_dropdownValues': _dropdownValues,
        '_dropdownOptions': _dropdownOptions,
        '_inputFieldKeys': _inputFieldKeys,
        '_sendData': _sendData,
      },
      setStateCallback: () => setState(() {}),
    );

    return parser.parse();
  }
}
