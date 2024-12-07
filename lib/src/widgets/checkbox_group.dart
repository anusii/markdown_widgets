/// Checkbox group widget.
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
    show contentWidthFactor;

class CheckboxGroup extends StatefulWidget {
  final String name;
  final List<Map<String, String?>> options;
  final Set<String> selectedValues;
  final bool isRequired;
  final Function(Set<String> selectedValues, Set<String> hiddenContentIds)
      onChanged;

  const CheckboxGroup({
    Key? key,
    required this.name,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    this.isRequired = false,
  }) : super(key: key);

  @override
  _CheckboxGroupState createState() => _CheckboxGroupState();
}

class _CheckboxGroupState extends State<CheckboxGroup> {
  late Set<String> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = Set<String>.from(widget.selectedValues);
  }

  @override
  void didUpdateWidget(CheckboxGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValues != oldWidget.selectedValues) {
      setState(() {
        _selectedValues = Set<String>.from(widget.selectedValues);
      });
    }
  }

  void _onChanged(String value, bool? isChecked, String? hiddenContentId) {
    setState(() {
      if (isChecked == true) {
        _selectedValues.add(value);
      } else {
        _selectedValues.remove(value);
      }
    });
    Set<String> hiddenContentIds = {};
    if (hiddenContentId != null) {
      hiddenContentIds.add(hiddenContentId);
    }
    widget.onChanged(_selectedValues, hiddenContentIds);
  }

  @override
  Widget build(BuildContext context) {
    // Get the font size of the text, default value is 14.0.

    double fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize ?? 14.0;

    // Assume the line height is 1.2 times the font size.

    double lineHeight = fontSize * 1.2;

    // Calculate half line height.

    double halfLineHeight = lineHeight / 2;

    List<Widget> children = [];

    if (widget.isRequired) {
      children.add(const Text(
        '(Required)',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ));
      children.add(const SizedBox(height: 4.0));
    }

    children.addAll(widget.options.map((option) {
      bool isChecked = _selectedValues.contains(option['value']!);
      return GestureDetector(
        onTap: () {
          _onChanged(option['value']!, !isChecked, option['hiddenContentId']);
        },
        child: Row(
          // Align the checkbox and text vertically at the top.

          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: isChecked,
              onChanged: (bool? newValue) {
                _onChanged(
                    option['value']!, newValue, option['hiddenContentId']);
              },
            ),
            Expanded(
              child: Padding(
                // Add a small padding above the text to align with checkbox.

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

            if (widget.isRequired) SizedBox(height: halfLineHeight),
            ...children,

            // Add a half line height of blank line after the last option.

            SizedBox(height: halfLineHeight),
          ],
        ),
      ),
    );
  }
}
