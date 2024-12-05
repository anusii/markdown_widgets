/// Markdown widget builder.
///
// Time-stamp: <Thursday 2024-11-14 21:33:15 +1100 Graham Williams>
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

import 'package:flutter/material.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:media_kit/media_kit.dart';

import 'package:markdown_widget_builder/src/utils/command_parser.dart';
import 'package:markdown_widget_builder/src/widgets/input_field.dart';

/// A widget that builds markdown content with interactive elements.
///
/// This widget parses the provided markdown content and commands, and renders
/// it with interactive elements such as sliders, radio buttons, checkboxes,
/// date pickers and dropdown menus. It also handles the submission of user
/// inputs to a specified server.
///
/// ```dart
/// MarkdownWidgetBuilder(
///   content: '# Sample Markdown',
///   title: 'Sample Title',
///   submitUrl: 'https://example.com/submit',
///   onMenuItemSelected: (title, content) {
///     // Handle menu item selection.
///   },
/// );
/// ```

class MarkdownWidgetBuilder extends StatefulWidget {
  /// The markdown content to be displayed.

  final String content;

  /// The title of the form page.

  final String title;

  /// The URL to which the user responses are submitted.

  final String? submitUrl;

  /// Callback when a menu item is selected.
  ///
  /// Provides the selected item's [title] and [content].

  final void Function(String title, String content)? onMenuItemSelected;

  /// Creates a [MarkdownWidgetBuilder] widget.
  ///
  /// [content] is required and represents the markdown content to be displayed.
  /// [title] is required and represents the title of the form page.
  /// [submitUrl] is optional and specifies the URL for form submission.
  /// [onMenuItemSelected] is an optional callback for menu item selection.

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
  final Map<String, String> _inputValues = {};
  final Map<String, double> _sliderValues = {};
  final Map<String, Map<String, dynamic>> _sliders = {};
  final Map<String, String?> _radioValues = {};
  final Map<String, Set<String>> _checkboxValues = {};
  final Map<String, DateTime?> _dateValues = {};
  final Map<String, String?> _dropdownValues = {};
  final Map<String, List<String>> _dropdownOptions = {};
  final Map<String, Player> _videoPlayers = {};
  final Map<String, AudioPlayer> _audioPlayers = {};
  final Map<String, GlobalKey<InputFieldState>> _inputFieldKeys = {};

  // Initialize the hidden content visibility map
  final Map<String, bool> _hiddenContentVisibility = {};

  @override
  void initState() {
    super.initState();

    // Ensure media_kit is initialised before use.

    MediaKit.ensureInitialized();
  }

  @override
  void dispose() {
    // Dispose of video players.

    _videoPlayers.forEach((key, player) {
      player.dispose();
    });

    // Release audio players.

    _audioPlayers.forEach((key, player) {
      player.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build content widgets every time to ensure UI updates.

    final contentWidgets = _buildContentWidgets(widget.content);

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: contentWidgets,
      ),
    );
  }

  /// Parses the markdown content and builds a list of widgets.
  ///
  /// [content] is the markdown content to parse.
  ///
  /// Returns a list of widgets representing the parsed content.

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
        '_hiddenContentVisibility': _hiddenContentVisibility,
      },
      setStateCallback: () => setState(() {}),
      surveyTitle: widget.title,
    );

    return parser.parse();
  }
}
