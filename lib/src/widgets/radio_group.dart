/// Radio button group widget.
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

class RadioGroup extends StatelessWidget {
  final String name;
  final List<Map<String, String?>> options;
  final String? selectedValue;
  final bool isRequired;
  final Function(String? value, String? hiddenContentId) onChanged;

  const RadioGroup({
    Key? key,
    required this.name,
    required this.options,
    this.selectedValue,
    required this.onChanged,
    this.isRequired = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the font size of the text, default value is 14.0.

    double fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize ?? 14.0;

    // Assume the line height is 1.2 times the font size.

    double lineHeight = fontSize * 1.2;

    // Half line height.

    double halfLineHeight = lineHeight / 2;

    List<Widget> children = [];

    if (isRequired) {
      children.add(const Text(
        '(Required)',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ));
      children.add(const SizedBox(height: 4.0));
    }

    children.addAll(options.map((option) {
      bool isChecked = selectedValue == option['value'];
      return InkWell(
        onTap: () {
          onChanged(option['value'], option['hiddenContentId']);
        },
        child: Row(
          // Align the radio button and text vertically at the top.

          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<String>(
              value: option['value']!,
              groupValue: selectedValue,
              onChanged: (value) {
                onChanged(value, option['hiddenContentId']);
              },
            ),
            Expanded(
              child: Padding(
                // Add a small padding above the text.

                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  option['label']!,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList());

    return Center(
      child: FractionallySizedBox(
        widthFactor: contentWidthFactor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add a half line height of blank line before the first option.

            if (isRequired) SizedBox(height: halfLineHeight),
            ...children,

            // Add a half line height of blank line after the last option.

            SizedBox(height: halfLineHeight),
          ],
        ),
      ),
    );
  }
}
