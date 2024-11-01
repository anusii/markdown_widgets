// App-wide constants.
//
// Copyright (C) 2024, Software Innovation Institute, ANU.
//
// Licensed under the GNU General Public License, Version 3 (the "License").
//
// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://www.gnu.org/licenses/>.
//
// Authors: Tony Chen

import 'package:flutter/material.dart';

const String applicationName = 'MarkDown Widgets';
const String applicationVersion = '0.1.0';
const String applicationRepo = 'https://github.com/anusii/markdown_widgets';
const String siiUrl = 'https://sii.anu.edu.au';
const String assetsPath = 'assets';
const String mediaPath = 'assets/media';
const String surveyAsset = 'assets/surveys.md';

double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

// Formatting constants used in the survey page.

const double contentWidthFactor = 0.6;
const double endingLines = 2;
