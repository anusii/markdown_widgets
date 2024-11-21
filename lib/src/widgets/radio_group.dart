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
    show contentWidthFactor;

class RadioGroup extends StatelessWidget {
  final String name;
  final List<Map<String, String>> options;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;

  const RadioGroup({
    Key? key,
    required this.name,
    required this.options,
    this.selectedValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: contentWidthFactor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: options.map((option) {
            return InkWell(
              onTap: () {
                onChanged(option['value']);
              },
              child: Row(
                children: [
                  Radio<String>(
                    value: option['value']!,
                    groupValue: selectedValue,
                    onChanged: onChanged,
                  ),
                  Expanded(
                    child: Text(
                      option['label']!,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
