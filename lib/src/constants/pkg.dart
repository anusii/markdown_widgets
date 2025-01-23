/// Package-wide constants.
///
// Time-stamp: <Sunday 2024-11-17 21:00:31 +1100 Graham Williams>
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

const String applicationName = 'Markdown Widgets Builder';
const String applicationVersion = '0.0.4';
const String applicationRepo =
    'https://github.com/anusii/markdown_widget_builder';
const String siiUrl = 'https://sii.anu.edu.au';

const String defaultFileName = 'survey.json';
const String defaultButtonText = 'Save';

const String defaultConfigFile = 'assets/config.json';

String _assetsPath = 'assets';
String _mediaPath = 'assets/surveys/media';
String _mdPath = 'assets/surveys/surveys.md';

String get assetsPath => _assetsPath;
String get mediaPath => _mediaPath;
String get mdPath => _mdPath;

void setAssetsPath(String newAssetsPath) {
  _assetsPath = newAssetsPath;
}

void setMediaPath(String newMediaPath) {
  _mediaPath = newMediaPath;
}

void setMdPath(String newMdPath) {
  _mdPath = newMdPath;
}

double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

// Formatting constants used in the survey page.

const double contentWidthFactor = 0.6;
const double endingLines = 2;
