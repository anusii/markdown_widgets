/// Text formatting utility.
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

// Function to manually justify text.
List<TextSpan> justifyText(String text, TextStyle style, double maxWidth) {
  List<String> lines = text.split('\n');
  List<TextSpan> justifiedSpans = [];

  // Update the style with black color
  TextStyle blackTextStyle = style.copyWith(color: Colors.black);

  for (String line in lines) {
    // Trim the line and check if it contains any whitespace
    String trimmedLine = line.trim();
    bool hasWhitespace = trimmedLine.contains(RegExp(r'\s'));

    List<String> units;

    if (hasWhitespace) {
      // If the line contains spaces, split into words
      units = trimmedLine.split(RegExp(r'\s+'));
    } else {
      // If no spaces, split into individual characters (grapheme clusters)
      units = trimmedLine.characters.toList();
    }

    if (units.length <= 1) {
      justifiedSpans.add(TextSpan(text: '$trimmedLine', style: blackTextStyle));
      continue;
    }

    // Create a TextPainter to measure the text width
    TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(text: trimmedLine, style: blackTextStyle),
    );

    // Set the maximum width
    textPainter.layout(minWidth: 0, maxWidth: maxWidth);
    double textWidth = textPainter.width;

    // Calculate the extra space needed
    double extraSpace = maxWidth - textWidth;

    if (extraSpace <= 0) {
      // If there's no extra space, no need to adjust
      justifiedSpans.add(TextSpan(text: '$trimmedLine', style: blackTextStyle));
      continue;
    }

    // Calculate the additional space to add between units
    int gapCount = units.length - 1;
    double additionalSpacePerGap = extraSpace / gapCount;

    // Build the adjusted line using InlineSpans
    List<InlineSpan> spanChildren = [];
    for (int i = 0; i < units.length; i++) {
      spanChildren.add(TextSpan(text: units[i], style: blackTextStyle));
      if (i < units.length - 1) {
        spanChildren.add(WidgetSpan(
          child: SizedBox(width: additionalSpacePerGap),
        ));
      }
    }

    justifiedSpans.add(TextSpan(children: spanChildren));
  }

  return justifiedSpans;
}
