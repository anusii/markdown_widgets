/// Button widget.
///
// Time-stamp: <Sunday 2023-12-31 18:58:28 +1100 Graham Williams>
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
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:solidpod/solidpod.dart' show writePod;

class ButtonWidget extends StatefulWidget {
  final String command;
  final Map<String, dynamic> state;

  ButtonWidget({
    Key? key,
    required this.command,
    required this.state,
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
        buttonText = args.length > 0 ? args[0] : 'Save';
        actionType = args.length > 1 ? int.tryParse(args[1]) ?? 0 : 0;
        actionParameter = args.length > 2 ? args[2] : 'result.json';
      } else {
        buttonText = 'Save';
        actionType = 0;
        actionParameter = 'result.json';
      }
    } else {
      buttonText = 'Save';
      actionType = 0;
      actionParameter = 'result.json';
    }
  }

  /// Collects the user responses from the state map.
  Map<String, dynamic> _collectData() {
    // Access the state variables and collect data
    final Map<String, dynamic> responses = {};

    final _inputValues = widget.state['_inputValues'] as Map<String, String>;
    final _sliderValues = widget.state['_sliderValues'] as Map<String, double>;
    final _radioValues = widget.state['_radioValues'] as Map<String, String?>;
    final _checkboxValues = widget.state['_checkboxValues'] as Map<String, Set<String>>;
    final _dateValues = widget.state['_dateValues'] as Map<String, DateTime?>;
    final _dropdownValues = widget.state['_dropdownValues'] as Map<String, String?>;

    // Add slider values
    _sliderValues.forEach((key, value) {
      responses[key] = value;
    });

    // Add radio values
    _radioValues.forEach((key, value) {
      responses[key] = value;
    });

    // Add checkbox values
    _checkboxValues.forEach((key, value) {
      // Convert Set to List
      responses[key] = value.toList();
    });

    // Add date values
    _dateValues.forEach((key, value) {
      if (value != null) {
        responses[key] =
        '${value.year}-${value.month.toString().padLeft(2, '0')}-'
            '${value.day.toString().padLeft(2, '0')}';
      } else {
        responses[key] = null;
      }
    });

    // Add dropdown values
    _dropdownValues.forEach((key, value) {
      responses[key] = value;
    });

    // Add text input values
    _inputValues.forEach((key, value) {
      responses[key] = value;
    });

    return responses;
  }

  Future<void> _handleButtonPress() async {
    final data = _collectData();

    if (actionType == 0) {
      // Save data locally as JSON
      String filename = actionParameter;

      if (kIsWeb) {
        // Web implementation: Download to Downloads folder
        final jsonContent = json.encode(data);

        final bytes = utf8.encode(jsonContent);
        final blob = html.Blob([bytes], 'application/json');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..click();
        html.Url.revokeObjectUrl(url);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data downloaded as $filename')),
        );
      } else {
        // Non-web implementation
        String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

        debugPrint('Selected directory: $selectedDirectory');

        if (selectedDirectory != null) {
          final filePath = '$selectedDirectory/$filename';
          final file = File(filePath);

          final jsonContent = json.encode(data);

          try {
            await file.writeAsString(jsonContent);
            debugPrint('File saved at: $filePath');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Data saved as $filePath')),
            );
          } catch (e) {
            debugPrint('Error saving file: $e');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving file: $e')),
            );
          }
        } else {
          debugPrint('No directory selected.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Save cancelled.')),
          );
        }
      }
    } else if (actionType == 1) {
      // Submit data via POST to URL
      String url = actionParameter;

      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Submission successful')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Submission failed: ${response.reasonPhrase}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    } else if (actionType == 2) {
      // Save data to POD
      String filename = actionParameter;

      try {
        await writePod(
          filename,
          json.encode(data),
          context,
          widget,
          encrypted: false,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully saved data to POD as $filename')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save data to POD: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid action type')),
      );
    }
  }

  List<String> _parseArguments(String argsString) {
    // Split by comma, handle quotes
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
