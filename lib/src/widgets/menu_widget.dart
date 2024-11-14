/// Menu widget.
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

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:markdown_widgets/src/constants/pkg.dart'
    show contentWidthFactor, screenWidth;

class MenuWidget extends StatelessWidget {
  final String menuContent;
  final String fullContent;
  final void Function(String title, String content) onMenuItemSelected;

  const MenuWidget({
    Key? key,
    required this.menuContent,
    required this.fullContent,
    required this.onMenuItemSelected,
  }) : super(key: key);

  /// Parse menu items.

  List<String> _parseMenuItems(String menuContent) {
    final lines = LineSplitter.split(menuContent).toList();
    final menuItems = <String>[];

    for (var line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.startsWith('- ')) {
        final item = trimmedLine.substring(2).trim();
        menuItems.add(item);
      }
    }

    return menuItems;
  }

  /// Extract the content corresponding to the selected menu item.

  String _extractSurveyContent(String markdownStr, String title) {
    final pattern = RegExp(
      r'^##\s+' + RegExp.escape(title) + r'\s*$',
      multiLine: true,
    );
    final matches = pattern.allMatches(markdownStr);

    if (matches.isEmpty) {
      return '';
    }

    // Get the position of the title.

    final startIndex = matches.first.end;

    // Find the next heading or the end of the document.

    final restOfDocument = markdownStr.substring(startIndex);
    final nextHeadingPattern = RegExp(r'^##\s+', multiLine: true);
    final nextMatch = nextHeadingPattern.firstMatch(restOfDocument);

    int endIndex;
    if (nextMatch != null) {
      endIndex = startIndex + nextMatch.start;
    } else {
      endIndex = markdownStr.length;
    }

    final content = markdownStr.substring(startIndex, endIndex).trim();
    return content;
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = _parseMenuItems(menuContent);
    final gridWidth = screenWidth(context) * contentWidthFactor;

    return Center(
      child: SizedBox(
        width: gridWidth,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: menuItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Buttons per row.
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 4, // Ratio of button (width / height).
          ),
          itemBuilder: (context, index) {
            final title = menuItems[index];
            return InkWell(
              onTap: () {
                // Extract the selected survey content.

                final surveyContent = _extractSurveyContent(fullContent, title);

                // Call the callback function to pass the selected menu item to
                // the parent widget.

                onMenuItemSelected(title, surveyContent);
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
