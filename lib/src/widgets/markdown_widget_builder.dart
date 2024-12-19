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

library;

import 'package:flutter/material.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:media_kit/media_kit.dart';

import 'package:markdown_widget_builder/src/utils/command_parser.dart';
import 'package:markdown_widget_builder/src/widgets/input_field.dart';

/// The MarkdownWidgetBuilder is a stateful widget that takes in markdown-like
/// content and a title. It uses the CommandParser to interpret custom commands
/// embedded in the content and build corresponding Flutter widgets, including
/// images, inputs, sliders, videos, audio players, and more. It also supports
/// pagination if the content is split into pages, allowing the user to navigate
/// between pages.

class MarkdownWidgetBuilder extends StatefulWidget {
  /// The markdown content containing custom commands to render.

  final String content;

  /// A title (e.g., for a survey or form) that may be displayed or used in
  /// callbacks.

  final String title;

  /// An optional submit URL that might be used for form submission.

  final String? submitUrl;

  /// A callback for when a menu item is selected, providing the selected title
  /// and content.

  final void Function(String title, String content)? onMenuItemSelected;

  const MarkdownWidgetBuilder({
    super.key,
    required this.content,
    required this.title,
    this.submitUrl,
    this.onMenuItemSelected,
  });

  @override
  _MarkdownWidgetBuilderState createState() => _MarkdownWidgetBuilderState();
}

class _MarkdownWidgetBuilderState extends State<MarkdownWidgetBuilder> {
  // State maps for various widget types and their values.

  final Map<String, String> _inputValues = {};
  final Map<String, double> _sliderValues = {};
  final Map<String, Map<String, dynamic>> _sliders = {};
  final Map<String, String?> _radioValues = {};
  final Map<String, Set<String>> _checkboxValues = {};
  final Map<String, DateTime?> _dateValues = {};
  final Map<String, String?> _dropdownValues = {};
  final Map<String, List<String>> _dropdownOptions = {};
  final Map<String, GlobalKey<InputFieldState>> _inputFieldKeys = {};
  final Map<String, bool> _hiddenContentVisibility = {};

  // Maps for hidden content and required widgets tracking.

  final Map<String, String> _hiddenContentMap = {};
  final Set<String> _requiredWidgets = {};

  // Media player instances for video and audio.

  final Map<String, Player> _videoPlayers = {};
  final Map<String, AudioPlayer> _audioPlayers = {};

  // Keeps track of the current page index if content is split into multiple
  // pages.

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    MediaKit.ensureInitialized();
  }

  @override
  void dispose() {
    // Dispose all video and audio players to release resources when the widget
    // is removed.

    _videoPlayers.forEach((key, player) {
      player.dispose();
    });
    _audioPlayers.forEach((key, player) {
      player.dispose();
    });
    super.dispose();
  }

  /// Builds the pages by parsing the content with CommandParser.
  /// CommandParser returns a list of pages, each page containing a list of
  /// widgets.

  List<List<Widget>> _buildPages() {
    final parser = CommandParser(
      context: context,
      content: widget.content,
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
        '_requiredWidgets': _requiredWidgets,
        '_hiddenContentMap': _hiddenContentMap,
      },
      setStateCallback: () => setState(() {}),
      surveyTitle: widget.title,
    );

    List<List<Widget>> pages = parser.parse();
    if (pages.isEmpty) {
      // If no pages are returned, at least have one empty page to avoid errors.

      pages = [[]];
    }
    return pages;
  }

  /// Navigate to the next page if available.

  void _goToNextPage(int totalPages) {
    if (_currentPage < totalPages - 1) {
      setState(() {
        _currentPage++;
      });
    }
  }

  /// Navigate to the previous page if available.

  void _goToPrevPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  /// Navigate directly to a specific page [index].

  void _goToPage(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  /// Builds a navigation bar for pagination, allowing the user to move between
  /// pages.

  Widget _buildPageNavBar(BuildContext context, int totalPages) {
    final prevButton = TextButton(
      onPressed: _currentPage > 0 ? _goToPrevPage : null,
      child: const Row(
        children: [
          Icon(Icons.chevron_left),
          Text('Previous'),
        ],
      ),
    );

    final nextButton = TextButton(
      onPressed: _currentPage < totalPages - 1
          ? () => _goToNextPage(totalPages)
          : null,
      child: const Row(
        children: [
          Text('Next'),
          Icon(Icons.chevron_right),
        ],
      ),
    );

    // Create a set of number buttons for direct page navigation.

    final numberButtons = List.generate(totalPages, (index) {
      final isSelected = index == _currentPage;
      return TextButton(
        onPressed: () => _goToPage(index),
        style: TextButton.styleFrom(
          backgroundColor: isSelected ? Colors.lightBlueAccent : null,
          shape: const CircleBorder(),
        ),
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      );
    });

    // The nav bar is centered and scrollable if there are many pages.

    return Center(
      child: FractionallySizedBox(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              prevButton,
              ...numberButtons,
              nextButton,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Parse the pages every time build() is called to reflect any state
    // changes.

    final pages = _buildPages();
    final currentPageWidgets = pages[_currentPage];

    // Show navigation only if multiple pages.

    final showPagination = pages.length > 1;

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Display the widgets for the current page.

          ...currentPageWidgets,

          // If pagination is needed, add spacing and the navigation bar.

          if (showPagination) const SizedBox(height: 20),
          if (showPagination) _buildPageNavBar(context, pages.length),
        ],
      ),
    );
  }
}
