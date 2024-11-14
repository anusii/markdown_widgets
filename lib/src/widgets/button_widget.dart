/// Button widget.
///
// Time-stamp: <Thursday 2024-11-14 21:40:08 +1100 Graham Williams>
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

import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;

import 'package:markdown_widgets/src/constants/pkg.dart';

class ButtonWidget extends StatefulWidget {
  final String command;
  final Map<String, dynamic> state;
  final String surveyTitle;

  ButtonWidget({
    Key? key,
    required this.command,
    required this.state,
    required this.surveyTitle,
  }) : super(key: key);

  @override
  _ButtonWidgetState createState() => _ButtonWidgetState();
}

class _ButtonWidgetState extends State<ButtonWidget> {
  late final String buttonText;
  late final int actionType;
  late final String actionParameter;

  @override
  void initState() {
    super.initState();
    _parseCommand();
  }

  void _parseCommand() {
    final buttonExp = RegExp(r'%% Button\((.+)\)');
    final buttonMatch = buttonExp.firstMatch(widget.command);

    if (buttonMatch != null) {
      final argsString = buttonMatch.group(1)!;
      final args = _parseArguments(argsString);

      if (args.isNotEmpty) {
        buttonText = args.isNotEmpty ? args[0] : defaultButtonText;
        actionType = args.length > 1 ? int.tryParse(args[1]) ?? 0 : 0;
        actionParameter = args.length > 2 ? args[2] : defaultFileName;
      } else {
        buttonText = defaultButtonText;
        actionType = 0;
        actionParameter = defaultFileName;
      }
    } else {
      buttonText = defaultButtonText;
      actionType = 0;
      actionParameter = defaultFileName;
    }
  }

  /// Collects the user responses from the state map.

  Map<String, dynamic> _collectData() {
    // Access the state variables and collect data.

    final Map<String, dynamic> responses = {};

    final _inputValues = widget.state['_inputValues'] as Map<String, String>;
    final _sliderValues = widget.state['_sliderValues'] as Map<String, double>;
    final _radioValues = widget.state['_radioValues'] as Map<String, String?>;
    final _checkboxValues =
        widget.state['_checkboxValues'] as Map<String, Set<String>>;
    final _dateValues = widget.state['_dateValues'] as Map<String, DateTime?>;
    final _dropdownValues =
        widget.state['_dropdownValues'] as Map<String, String?>;

    // Add slider values.

    _sliderValues.forEach((key, value) {
      responses[key] = value;
    });

    // Add radio values.

    _radioValues.forEach((key, value) {
      responses[key] = value;
    });

    // Add checkbox values.

    _checkboxValues.forEach((key, value) {
      // Convert Set to List.

      responses[key] = value.toList();
    });

    // Add date values.

    _dateValues.forEach((key, value) {
      if (value != null) {
        responses[key] =
            '${value.year}-${value.month.toString().padLeft(2, '0')}-'
            '${value.day.toString().padLeft(2, '0')}';
      } else {
        responses[key] = null;
      }
    });

    // Add dropdown values.

    _dropdownValues.forEach((key, value) {
      responses[key] = value;
    });

    // Add text input values.

    _inputValues.forEach((key, value) {
      responses[key] = value;
    });

    return responses;
  }

  Future<void> _handleButtonPress() async {
    final data = _collectData();

    if (actionType == 0) {
      // Save the data locally as a JSON file.

      await _saveDataLocally(data);
    } else if (actionType == 1) {
      // Submit the data to a URL.

      await _submitDataToUrl(data);
    } else {
      // Invalid action type.

      _showInvalidActionTypeMessage();
    }
  }

  Future<void> _saveDataLocally(Map<String, dynamic> data) async {
    debugPrint('Collected Data:');
    debugPrint(json.encode(data));

    // Generate the default filename based on the survey title.

    String defaultFileName = _generateFilename(widget.surveyTitle);

    if (kIsWeb) {
      // For web platforms.

      await _downloadDataForWeb(data, defaultFileName);
    } else {
      // For non-web platforms.

      await _saveDataForNonWeb(data, defaultFileName);
    }
  }

  Future<void> _downloadDataForWeb(
      Map<String, dynamic> data, String defaultFileName) async {
    final jsonContent = json.encode(data);

    final bytes = utf8.encode(jsonContent);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Create an anchor element, set its href and download attributes,
    // and click it.

    html.AnchorElement(href: url)
      ..setAttribute('download', defaultFileName)
      ..click();

    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data downloaded as $defaultFileName')),
    );
  }

  Future<void> _saveDataForNonWeb(
      Map<String, dynamic> data, String defaultFileName) async {
    String? selectedFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Please choose a filename and path to save the result',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (selectedFile != null) {
      final file = File(selectedFile);
      final jsonContent = json.encode(data);

      try {
        await file.writeAsString(jsonContent);
        debugPrint('File saved at $selectedFile');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data saved as $selectedFile')),
        );
      } catch (e) {
        debugPrint('Error saving file: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving file: $e')),
        );
      }
    } else {
      debugPrint('Save file dialog was cancelled.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save cancelled.')),
      );
    }
  }

  Future<void> _submitDataToUrl(Map<String, dynamic> data) async {
    String url = actionParameter;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission successful')),
        );
      } else {
        debugPrint('Response body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Submission failed: ${response.statusCode} '
                    '${response.reasonPhrase}'),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Submission failed: $e');
      debugPrint('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e')),
      );
    }
  }

  void _showInvalidActionTypeMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid action type')),
    );
  }

  /// Generates a filename based on the survey title.

  String _generateFilename(String title) {
    // Convert to lowercase, replace special characters with underscores.

    String filename = title.toLowerCase();
    filename = filename.replaceAll(RegExp(r'[^a-z0-9]+'), '_');

    // Remove leading/trailing underscores.

    filename = filename.replaceAll(RegExp(r'^_+|_+$'), '');
    filename = '$filename.json';
    return filename;
  }

  List<String> _parseArguments(String argsString) {
    // Split by comma, handle quotes.

    final args = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    String quoteChar = '';

    for (int i = 0; i < argsString.length; i++) {
      final char = argsString[i];

      if (char == '\'' || char == '"') {
        if (inQuotes && char == quoteChar) {
          inQuotes = false;
        } else if (!inQuotes) {
          inQuotes = true;
          quoteChar = char;
        }
        continue;
      }

      if (char == ',' && !inQuotes) {
        args.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    if (buffer.isNotEmpty) {
      args.add(buffer.toString().trim());
    }

    return args;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: _handleButtonPress,
        child: Text(buttonText),
      ),
    );
  }
}
