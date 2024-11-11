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
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ButtonWidget extends StatelessWidget {
  final String command;
  final Map<String, dynamic> state;

  ButtonWidget({
    Key? key,
    required this.command,
    required this.state,
  }) : super(key: key);

  late final String buttonText;
  late final int actionType;
  late final String actionParameter;

  void _parseCommand() {
    final buttonExp = RegExp(r'%% Button\((.+)\)');
    final buttonMatch = buttonExp.firstMatch(command);

    if (buttonMatch != null) {
      final argsString = buttonMatch.group(1)!;
      final args = _parseArguments(argsString);

      if (args.isNotEmpty) {
        buttonText = args.length > 0 ? args[0] : 'Submit';
        actionType = args.length > 1 ? int.tryParse(args[1]) ?? 0 : 0;
        actionParameter = args.length > 2 ? args[2] : 'result.json';
      } else {
        buttonText = 'Submit';
        actionType = 0;
        actionParameter = 'result.json';
      }
    } else {
      buttonText = 'Submit';
      actionType = 0;
      actionParameter = 'result.json';
    }
  }

  /// Submits the user responses to the specified URL.
  Map<String, dynamic> _collectData() {
    // Access the state variables and collect data
    final Map<String, dynamic> responses = {};

    final _inputValues = state['_inputValues'] as Map<String, String>;
    final _sliderValues = state['_sliderValues'] as Map<String, double>;
    final _radioValues = state['_radioValues'] as Map<String, String?>;
    final _checkboxValues =
        state['_checkboxValues'] as Map<String, Set<String>>;
    final _dateValues = state['_dateValues'] as Map<String, DateTime?>;
    final _dropdownValues = state['_dropdownValues'] as Map<String, String?>;

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

  Future<void> _handleButtonPress(BuildContext context) async {
    final data = _collectData();

    if (actionType == 0) {
      // Save data locally as JSON
      String filename = actionParameter;

      // Prompt dialog to confirm or change filename
      final TextEditingController _controller =
      TextEditingController(text: filename);

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Save File'),
            content: TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Filename'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  String fileName = _controller.text;
                  Navigator.pop(context);

                  // Get the directory to save the file
                  Directory directory;
                  if (Platform.isAndroid || Platform.isIOS) {
                    directory = await getApplicationDocumentsDirectory();
                  } else {
                    directory = await getDownloadsDirectory() ??
                        await getApplicationDocumentsDirectory();
                  }

                  final filePath = '${directory.path}/$fileName';

                  // Write the data to the file
                  final file = File(filePath);
                  await file.writeAsString(json.encode(data));

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Data saved as $fileName')),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
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
    _parseCommand();

    return ElevatedButton(
      onPressed: () {
        _handleButtonPress(context);
      },
      child: Text(buttonText),
    );
  }
}
