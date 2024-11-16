/// Text heading widget.
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

import 'package:markdown_widget_builder/src/constants/pkg.dart'
    show contentWidthFactor, screenWidth;
import 'package:markdown_widget_builder/src/utils/justify_text.dart';

class TextHeadingWidget extends StatelessWidget {
  final int level;
  final String content;
  final String align;

  const TextHeadingWidget({
    Key? key,
    required this.level,
    required this.content,
    required this.align,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gridWidth = screenWidth(context) * contentWidthFactor;

    double fontSize;
    switch (level) {
      case 1:
        fontSize = 64.0;
        break;
      case 2:
        fontSize = 48.0;
        break;
      case 3:
        fontSize = 36.0;
        break;
      case 4:
        fontSize = 24.0;
        break;
      case 5:
        fontSize = 16.0;
        break;
      case 6:
        fontSize = 12.0;
        break;
      default:
        fontSize = 16.0;
    }

    TextAlign textAlign;
    switch (align.toLowerCase()) {
      case 'left':
        textAlign = TextAlign.left;
        break;
      case 'right':
        textAlign = TextAlign.right;
        break;
      case 'center':
        textAlign = TextAlign.center;
        break;
      case 'justify':
        textAlign = TextAlign.left;
        break;
      default:
        textAlign = TextAlign.left;
    }

    TextStyle textStyle =
        TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold);

    if (align.toLowerCase() == 'justify') {
      List<TextSpan> justifiedSpans =
          justifyText(content.trim(), textStyle, gridWidth);

      return Center(
        child: Container(
          width: gridWidth,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: RichText(
            text: TextSpan(children: justifiedSpans),
            textAlign: textAlign,
          ),
        ),
      );
    } else {
      return Center(
        child: Container(
          width: gridWidth,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            content,
            textAlign: textAlign,
            style: textStyle,
          ),
        ),
      );
    }
  }
}
