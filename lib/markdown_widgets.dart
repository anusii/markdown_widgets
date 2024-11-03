// Widgets for survey questionnaires defined using markdown-like syntax.
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
// FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://www.gnu.org/licenses/>.
//
// Authors: Tony Chen

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:markdown_widgets/constants/constants.dart'
    show contentWidthFactor, screenWidth, mediaPath, endingLines;

class MarkdownWidgetBuilder extends StatefulWidget {
  final String content;
  final String title;
  final String? submitUrl;

  final void Function(String title, String content)? onMenuItemSelected;

  const MarkdownWidgetBuilder({
    Key? key,
    required this.content,
    required this.title,
    this.submitUrl,
    this.onMenuItemSelected,
  }) : super(key: key);

  @override
  _MarkdownWidgetBuilderState createState() => _MarkdownWidgetBuilderState();
}

class _MarkdownWidgetBuilderState extends State<MarkdownWidgetBuilder> {
  // Submit URL
  String? _submitUrl;

  // Whether the content has a menu
  bool _hasMenu = false;

  // Store the slider values
  final Map<String, double> _sliderValues = {};

  // Store the slider parameters
  final Map<String, Map<String, dynamic>> _sliders = {};

  // Store the radio values
  final Map<String, String?> _radioValues = {};

  // Store the checkbox values
  final Map<String, Set<String>> _checkboxValues = {};

  // Store the text input controllers
  final Map<String, TextEditingController> _textControllers = {};

  // Store the date values
  final Map<String, DateTime?> _dateValues = {};

  // Store dropdown values
  final Map<String, String?> _dropdownValues = {};

  // Store dropdown options
  final Map<String, List<String>> _dropdownOptions = {};

  // Store video controllers
  final Map<String, VideoPlayerController> _videoControllers = {};

  // Store audio players
  final Map<String, AudioPlayer> _audioPlayers = {};

  // Store audio durations
  final Map<String, Duration> _audioDurations = {};

  // Store audio positions
  final Map<String, Duration> _audioPositions = {};

  // Store audio player states
  final Map<String, PlayerState> _audioPlayerStates = {};

  @override
  void initState() {
    super.initState();
    _submitUrl = widget.submitUrl ?? 'http://127.0.0.1/feedback';
  }

  @override
  void dispose() {
    // Dispose of video controllers
    _videoControllers.forEach((key, controller) {
      controller.dispose();
    });
    // Release audio players
    _audioPlayers.forEach((key, player) {
      player.dispose();
    });
    // Dispose of text controllers
    _textControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  // Send data method
  Future<void> _sendData() async {
    final Map<String, dynamic> responses = {};

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

    // Add text input values
    _textControllers.forEach((key, controller) {
      responses[key] = controller.text;
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

    final Map<String, dynamic> data = {
      'title': widget.title,
      'responses': responses,
    };

    print('Submitting the following data: $data');

    try {
      final response = await http.post(
        Uri.parse(_submitUrl!),
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
  }

  // Build the content widget method
  List<Widget> _buildContentWidgets(String content) {
    List<Widget> widgets = [];

    // Regular expression to match description blocks
    final RegExp descriptionBlockExp =
        RegExp(r'%% Description-Begin([\s\S]*?)%% Description-End');

    // Regular expression to match heading blocks with alignment
    final RegExp headingAlignBlockExp =
        RegExp(r'%% H([1-6])(Left|Right|Center|Justify)?'
            r'-Begin([\s\S]*?)%% H\1(?:\2)?-End');

    // Regular expression to match alignment blocks
    final RegExp alignBlockExp = RegExp(
        r'%% Align(Left|Right|Center|Justify)-Begin([\s\S]*?)%% Align\1-End');

    // Regular expression to match image commands
    final RegExp imageExp = RegExp(r'%% Image\(([^)]+)\)');

    // Regular expression to match video commands
    final RegExp videoExp = RegExp(r'%% Video\(([^)]+)\)');

    // Regular expression to match audio commands
    final RegExp audioExp = RegExp(r'%% Audio\(([^)]+)\)');

    // Regular expression to match %% Menu blocks
    final RegExp menuBlockExp = RegExp(r'%% Menu-Begin([\s\S]*?)%% Menu-End');

    // Parse the menu blocks and replace with placeholders
    int menuIndex = 0;
    final Map<String, String> menuPlaceholders = {};
    content = content.replaceAllMapped(menuBlockExp, (match) {
      String placeholder = '%%MenuPlaceholder$menuIndex%%';
      menuPlaceholders[placeholder] = match.group(1)!;
      menuIndex++;
      return placeholder;
    });

    // Check if the content has a menu
    _hasMenu = menuIndex > 0;

    // If there is a menu, trim the content to only process the menu part
    if (_hasMenu) {
      // If there is a menu, only process the menu part and ignore the rest
      final menuPlaceholderPattern = RegExp(r'%%MenuPlaceholder\d+%%');
      final menuMatch = menuPlaceholderPattern.firstMatch(content);

      if (menuMatch != null) {
        // Keep only the content before the menu placeholder
        // (including the menu itself)
        final menuEndIndex = menuMatch.end;
        content = content.substring(0, menuEndIndex);
      }
    }

    // Parse the description blocks and replace with placeholders
    int descriptionIndex = 0;
    final Map<String, String> descriptionPlaceholders = {};
    content = content.replaceAllMapped(descriptionBlockExp, (match) {
      String placeholder = '%%DescriptionPlaceholder$descriptionIndex%%';
      descriptionPlaceholders[placeholder] = match.group(1)!;
      descriptionIndex++;
      return placeholder;
    });

    // Parse heading blocks with alignment and replace with placeholders
    int headingIndex = 0;
    final Map<String, Map<String, String>> headingPlaceholders = {};
    content = content.replaceAllMapped(headingAlignBlockExp, (match) {
      String placeholder = '%%HeadingPlaceholder$headingIndex%%';
      headingPlaceholders[placeholder] = {
        'level': match.group(1)!,
        'align': match.group(2) ?? 'Left',
        'content': match.group(3)!,
      };
      headingIndex++;
      return placeholder;
    });

    // Parse alignment blocks and replace with placeholders
    int alignIndex = 0;
    final Map<String, Map<String, String>> alignPlaceholders = {};
    content = content.replaceAllMapped(alignBlockExp, (match) {
      String placeholder = '%%AlignPlaceholder$alignIndex%%';
      alignPlaceholders[placeholder] = {
        'align': match.group(1)!,
        'content': match.group(2)!
      };
      alignIndex++;
      return placeholder;
    });

    // Regular expression to match custom commands
    final RegExp customCommandExp = RegExp(r'(%% Slider\([^\)]+\)|%% Submit|'
        r'%% Radio\([^\)]+\)|%% Checkbox\([^\)]+\)|'
        r'%% InputSL\([^\)]+\)|%% InputML\([^\)]+\)|'
        r'%% Calendar\([^\)]+\)|%% Dropdown\([^\)]+\)|'
        r'%% Image\([^\)]+\)|%% Video\([^\)]+\)|%% Audio\([^\)]+\)|'
        r'%% Timer\([^\)]+\)|%% EmptyLine|'
        r'%%DescriptionPlaceholder\d+%%|'
        r'%%HeadingPlaceholder\d+%%|'
        r'%%AlignPlaceholder\d+%%|'
        r'%%MenuPlaceholder\d+%%)');

    final matches = customCommandExp.allMatches(content).toList();

    int lastIndex = 0;

    // Parse the radio group variables
    String? currentRadioGroupName;
    List<Map<String, String>> currentRadioOptions = [];

    // Parse the checkbox group variables
    String? currentCheckboxGroupName;
    List<Map<String, String>> currentCheckboxOptions = [];

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      if (match.start > lastIndex) {
        // Extract the markdown content between custom commands
        String markdownContent = content.substring(lastIndex, match.start);
        if (markdownContent.trim().isNotEmpty) {
          // Build any unfinished radio or checkbox groups
          if (currentRadioGroupName != null) {
            widgets.add(
                _buildRadioGroup(currentRadioGroupName, currentRadioOptions));
            currentRadioGroupName = null;
            currentRadioOptions = [];
          }
          if (currentCheckboxGroupName != null) {
            widgets.add(_buildCheckboxGroup(
                currentCheckboxGroupName, currentCheckboxOptions));
            currentCheckboxGroupName = null;
            currentCheckboxOptions = [];
          }

          widgets.add(_buildMarkdown(markdownContent));
        }
      }

      // Parse the command
      String command = match.group(0)!;

      if (command.startsWith('%%MenuPlaceholder')) {
        // Menu block placeholder to get the actual content
        String menuContent = menuPlaceholders[command]!;

        // Build the menu widget
        widgets.add(_buildMenu(menuContent, widget.content));
      } else if (command.startsWith('%%DescriptionPlaceholder')) {
        // Description block placeholder to get the actual content
        String descriptionContent = descriptionPlaceholders[command]!;

        // Add the description box directly to the widgets list
        widgets.add(_buildDescriptionBox(descriptionContent));
      } else if (command.startsWith('%%HeadingPlaceholder')) {
        // Heading block placeholder with alignment
        final headingInfo = headingPlaceholders[command]!;
        final level = int.parse(headingInfo['level']!);
        final align = headingInfo['align']!;
        final headingContent = headingInfo['content']!;

        // Build the heading widget
        widgets.add(_buildHeading(level, headingContent, align));
      } else if (command.startsWith('%%AlignPlaceholder')) {
        // Alignment block placeholder
        final alignInfo = alignPlaceholders[command]!;
        final align = alignInfo['align']!;
        final alignContent = alignInfo['content']!;

        // Build the aligned text widget
        widgets.add(_buildAlignedText(align, alignContent));
      } else if (command.startsWith('%% Image')) {
        final imageMatch = imageExp.firstMatch(command);
        if (imageMatch != null) {
          final filename = imageMatch.group(1)!.trim();
          widgets.add(_buildImageWidget(filename));
        }
      } else if (command.startsWith('%% Video')) {
        final videoMatch = videoExp.firstMatch(command);
        if (videoMatch != null) {
          final filename = videoMatch.group(1)!.trim();
          widgets.add(_buildVideoWidget(filename));
        }
      } else if (command.startsWith('%% Audio')) {
        final audioMatch = audioExp.firstMatch(command);
        if (audioMatch != null) {
          final filename = audioMatch.group(1)!.trim();
          widgets.add(_buildAudioWidget(filename));
        }
      } else if (command.startsWith('%% Timer')) {
        // Build any unfinished radio or checkbox groups
        if (currentRadioGroupName != null) {
          widgets.add(
              _buildRadioGroup(currentRadioGroupName, currentRadioOptions));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }
        if (currentCheckboxGroupName != null) {
          widgets.add(_buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        final timerExp = RegExp(r'%% Timer\(([^\)]+)\)');
        final timerMatch = timerExp.firstMatch(command);
        if (timerMatch != null) {
          final timeString = timerMatch.group(1)!.trim();

          // Build the timer widget
          widgets.add(_buildTimerWidget(timeString));
        }
      } else if (command.startsWith('%% EmptyLine')) {
        // Build any unfinished radio or checkbox groups
        if (currentRadioGroupName != null) {
          widgets.add(
              _buildRadioGroup(currentRadioGroupName, currentRadioOptions));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }
        if (currentCheckboxGroupName != null) {
          widgets.add(_buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        // Add an empty line
        final lineHeight = DefaultTextStyle.of(context).style.fontSize ?? 16.0;
        widgets.add(SizedBox(height: lineHeight));
      } else if (command.startsWith('%% Slider')) {
        // Build any unfinished radio or checkbox groups
        if (currentRadioGroupName != null) {
          widgets.add(
              _buildRadioGroup(currentRadioGroupName, currentRadioOptions));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }
        if (currentCheckboxGroupName != null) {
          widgets.add(_buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        // Parse the slider parameters
        final sliderExp = RegExp(r'%% Slider\(([^,]+),\s*([\d\.]+),'
            r'\s*([\d\.]+),\s*([\d\.]+),\s*([\d\.]+)\)');
        final sliderMatch = sliderExp.firstMatch(command);

        if (sliderMatch != null) {
          final name = sliderMatch.group(1)!.trim();
          final min = double.parse(sliderMatch.group(2)!);
          final max = double.parse(sliderMatch.group(3)!);
          final defaultValue = double.parse(sliderMatch.group(4)!);
          final step = double.parse(sliderMatch.group(5)!);

          // Store the slider parameters
          _sliders[name] = {
            'min': min,
            'max': max,
            'defaultValue': defaultValue,
            'step': step,
          };

          // Initialise the slider value
          if (!_sliderValues.containsKey(name)) {
            _sliderValues[name] = defaultValue;
          }

          // Build the slider widget
          widgets.add(_buildSlider(name));
        }
      } else if (command.startsWith('%% Submit')) {
        // Build any unfinished radio or checkbox groups
        if (currentRadioGroupName != null) {
          widgets.add(
              _buildRadioGroup(currentRadioGroupName, currentRadioOptions));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }
        if (currentCheckboxGroupName != null) {
          widgets.add(_buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        // Build the submit button
        widgets.add(
          Center(
            child: SizedBox(
              width: 100.0,
              child: ElevatedButton(
                onPressed: _sendData,
                child: const Text('Submit'),
              ),
            ),
          ),
        );
      } else if (command.startsWith('%% Radio')) {
        // Build any unfinished checkbox groups
        if (currentCheckboxGroupName != null) {
          widgets.add(_buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        final radioExp = RegExp(r'%% Radio\(([^,]+),\s*([^,]+),\s*([^\)]+)\)');
        final radioMatch = radioExp.firstMatch(command);

        if (radioMatch != null) {
          final name = radioMatch.group(1)!.trim();
          final value = radioMatch.group(2)!.trim();
          final label = radioMatch.group(3)!.trim();

          // If starting a new radio group or the group name has changed
          if (currentRadioGroupName == null || currentRadioGroupName != name) {
            // If there is a previous radio group, build it first
            if (currentRadioGroupName != null) {
              widgets.add(
                  _buildRadioGroup(currentRadioGroupName, currentRadioOptions));
              currentRadioOptions = [];
            }

            currentRadioGroupName = name;
            // Initialise the selected value of the group
            if (!_radioValues.containsKey(name)) {
              _radioValues[name] = null;
            }
          }

          // Add options to the current group
          currentRadioOptions.add({'value': value, 'label': label});

          // Check if the next command belongs to the same group
          bool isLastOption = true;
          if (i + 1 < matches.length) {
            final nextMatch = matches[i + 1];
            final nextCommand = nextMatch.group(0)!;
            final nextRadioMatch = radioExp.firstMatch(nextCommand);
            if (nextRadioMatch != null) {
              final nextName = nextRadioMatch.group(1)!.trim();
              if (nextName == currentRadioGroupName) {
                isLastOption = false;
              }
            }
          }

          // If there are no more options, build the radio group
          if (isLastOption) {
            widgets.add(
                _buildRadioGroup(currentRadioGroupName, currentRadioOptions));
            currentRadioGroupName = null;
            currentRadioOptions = [];
          }
        }
      } else if (command.startsWith('%% Checkbox')) {
        // Build any unfinished radio groups
        if (currentRadioGroupName != null) {
          widgets.add(
              _buildRadioGroup(currentRadioGroupName, currentRadioOptions));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }

        final checkboxExp =
            RegExp(r'%% Checkbox\(([^,]+),\s*([^,]+),\s*([^\)]+)\)');
        final checkboxMatch = checkboxExp.firstMatch(command);

        if (checkboxMatch != null) {
          final name = checkboxMatch.group(1)!.trim();
          final value = checkboxMatch.group(2)!.trim();
          final label = checkboxMatch.group(3)!.trim();

          // If starting a new checkbox group or the group name has changed
          if (currentCheckboxGroupName == null ||
              currentCheckboxGroupName != name) {
            // If there is a previous checkbox group, build it first
            if (currentCheckboxGroupName != null) {
              widgets.add(_buildCheckboxGroup(
                  currentCheckboxGroupName, currentCheckboxOptions));
              currentCheckboxOptions = [];
            }

            currentCheckboxGroupName = name;
            // Initialise the selected values of the group
            if (!_checkboxValues.containsKey(name)) {
              _checkboxValues[name] = {};
            }
          }

          // Add options to the current group
          currentCheckboxOptions.add({'value': value, 'label': label});

          // Check if the next command belongs to the same group
          bool isLastOption = true;
          if (i + 1 < matches.length) {
            final nextMatch = matches[i + 1];
            final nextCommand = nextMatch.group(0)!;
            final nextCheckboxMatch = checkboxExp.firstMatch(nextCommand);
            if (nextCheckboxMatch != null) {
              final nextName = nextCheckboxMatch.group(1)!.trim();
              if (nextName == currentCheckboxGroupName) {
                isLastOption = false;
              }
            }
          }

          // If there are no more options, build the checkbox group
          if (isLastOption) {
            widgets.add(_buildCheckboxGroup(
                currentCheckboxGroupName, currentCheckboxOptions));
            currentCheckboxGroupName = null;
            currentCheckboxOptions = [];
          }
        }
      } else if (command.startsWith('%% Calendar')) {
        // Build any unfinished radio or checkbox groups
        if (currentRadioGroupName != null) {
          widgets.add(
              _buildRadioGroup(currentRadioGroupName, currentRadioOptions));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }
        if (currentCheckboxGroupName != null) {
          widgets.add(_buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        final calendarExp = RegExp(r'%% Calendar\(([^\)]+)\)');
        final calendarMatch = calendarExp.firstMatch(command);
        if (calendarMatch != null) {
          final name = calendarMatch.group(1)!.trim();

          // Initialise date value
          if (!_dateValues.containsKey(name)) {
            _dateValues[name] = null;
          }

          // Build the calendar field
          widgets.add(_buildCalendarField(name));
        }
      } else if (command.startsWith('%% Dropdown')) {
        // Build any unfinished radio or checkbox groups
        if (currentRadioGroupName != null) {
          widgets.add(
              _buildRadioGroup(currentRadioGroupName, currentRadioOptions));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }
        if (currentCheckboxGroupName != null) {
          widgets.add(_buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        final dropdownExp = RegExp(r'%% Dropdown\(([^\)]+)\)');
        final dropdownMatch = dropdownExp.firstMatch(command);
        if (dropdownMatch != null) {
          final name = dropdownMatch.group(1)!.trim();

          // Initialise dropdown options and selected value
          if (!_dropdownValues.containsKey(name)) {
            _dropdownValues[name] = null;
          }
          if (!_dropdownOptions.containsKey(name)) {
            _dropdownOptions[name] = [];
          }

          // Parse the options from the following markdown list
          int optionsStartIndex = match.end;
          int optionsEndIndex = content.length;

          // Look ahead to find where the options list ends
          // It ends when a line does not start with '-' or the next command
          // starts
          int currentIndex = optionsStartIndex;
          final lines = content.substring(optionsStartIndex).split('\n');
          final List<String> options = [];
          int lineOffset = 0;
          for (var line in lines) {
            final trimmedLine = line.trim();
            if (trimmedLine.startsWith('- ')) {
              options.add(trimmedLine.substring(2).trim());
              lineOffset += line.length + 1; // +1 for the newline character
            } else if (trimmedLine.isEmpty) {
              lineOffset += line.length + 1;
            } else {
              // Non-list item or next command
              break;
            }
          }

          optionsEndIndex = optionsStartIndex + lineOffset;

          _dropdownOptions[name] = options;

          // Build the dropdown widget
          widgets.add(_buildDropdown(name, options));

          // Update the lastIndex to the end of the options list
          lastIndex = optionsEndIndex;
          continue; // Skip updating lastIndex again at the end of loop
        }
      }
      // Parse the input field command for single-line and multi-line input
      else if (command.startsWith('%% InputSL')) {
        // Build any unfinished radio or checkbox groups
        if (currentRadioGroupName != null) {
          widgets.add(
              _buildRadioGroup(currentRadioGroupName, currentRadioOptions));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }
        if (currentCheckboxGroupName != null) {
          widgets.add(_buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        final inputSLExp = RegExp(r'%% InputSL\(([^\)]+)\)');
        final inputSLMatch = inputSLExp.firstMatch(command);
        if (inputSLMatch != null) {
          final name = inputSLMatch.group(1)!.trim();

          if (!_textControllers.containsKey(name)) {
            _textControllers[name] = TextEditingController();
          }

          widgets.add(_buildInputField(name, isMultiLine: false));
        }
      } else if (command.startsWith('%% InputML')) {
        // Build any unfinished radio or checkbox groups
        if (currentRadioGroupName != null) {
          widgets.add(
              _buildRadioGroup(currentRadioGroupName, currentRadioOptions));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }
        if (currentCheckboxGroupName != null) {
          widgets.add(_buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        final inputMLExp = RegExp(r'%% InputML\(([^\)]+)\)');
        final inputMLMatch = inputMLExp.firstMatch(command);
        if (inputMLMatch != null) {
          final name = inputMLMatch.group(1)!.trim();

          if (!_textControllers.containsKey(name)) {
            _textControllers[name] = TextEditingController();
          }

          widgets.add(_buildInputField(name, isMultiLine: true));
        }
      }

      lastIndex = match.end;
    }

    // Parse the markdown content after the last custom command
    if (lastIndex < content.length) {
      String markdownContent = content.substring(lastIndex);
      if (markdownContent.trim().isNotEmpty) {
        // Build any unfinished radio or checkbox groups before adding new
        // content
        if (currentRadioGroupName != null) {
          widgets.add(
              _buildRadioGroup(currentRadioGroupName, currentRadioOptions));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }
        if (currentCheckboxGroupName != null) {
          widgets.add(_buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        // If there is no menu, the content after the menu will need to be
        // shown
        if (!_hasMenu) {
          widgets.add(_buildMarkdown(markdownContent));
        }
      }
    }

    // Build any unfinished radio or checkbox groups (if any)
    if (currentRadioGroupName != null) {
      widgets.add(_buildRadioGroup(currentRadioGroupName, currentRadioOptions));
    }
    if (currentCheckboxGroupName != null) {
      widgets.add(_buildCheckboxGroup(
          currentCheckboxGroupName, currentCheckboxOptions));
    }

    // Add some space at the end
    final lineHeight = DefaultTextStyle.of(context).style.fontSize ?? 16.0;
    widgets.add(SizedBox(height: lineHeight * endingLines));

    return widgets;
  }

  // Parse the time string and return the total seconds
  int _parseTimeString(String timeString) {
    final timeRegExp = RegExp(r'(?:(\d+)h)?\s*(?:(\d+)m)?\s*(?:(\d+)s)?');
    final match = timeRegExp.firstMatch(timeString);
    if (match != null) {
      final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
      final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
      final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;

      final totalSeconds = hours * 3600 + minutes * 60 + seconds;
      return totalSeconds;
    } else {
      // If parsing fails, return 0
      return 0;
    }
  }

  Widget _buildTimerWidget(String timeString) {
    final totalSeconds = _parseTimeString(timeString);
    if (totalSeconds <= 0) {
      return const Text('Invalid timer duration');
    }

    return TimerWidget(
      totalSeconds: totalSeconds,
    );
  }

  // Build description block widget
  Widget _buildDescriptionBox(String content) {
    final gridWidth = screenWidth(context) * contentWidthFactor;

    return Center(
      child: Container(
        width: gridWidth,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: MarkdownBody(
          data: content,
          onTapLink: (text, href, title) async {
            if (href != null) {
              final uri = Uri.parse(href);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cannot launch $href')),
                );
              }
            }
          },
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  // Build heading widget with alignment
  Widget _buildHeading(int level, String content, String align) {
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
        textAlign = TextAlign.left; // We'll handle justification manually
        break;
      default:
        textAlign = TextAlign.left;
    }

    TextStyle textStyle =
        TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold);

    if (align.toLowerCase() == 'justify') {
      List<TextSpan> justifiedSpans =
          _justifyText(content.trim(), textStyle, gridWidth);

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

  // Build aligned text widget
  Widget _buildAlignedText(String align, String content) {
    final gridWidth = screenWidth(context) * contentWidthFactor;

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

    TextStyle textStyle = const TextStyle(fontSize: 16);

    if (align.toLowerCase() == 'justify') {
      List<TextSpan> justifiedSpans =
          _justifyText(content.trim(), textStyle, gridWidth);

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

  // Function to manually justify text
  List<TextSpan> _justifyText(String text, TextStyle style, double maxWidth) {
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
        justifiedSpans
            .add(TextSpan(text: '$trimmedLine', style: blackTextStyle));
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
        justifiedSpans
            .add(TextSpan(text: '$trimmedLine', style: blackTextStyle));
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

  // Build Markdown widget
  Widget _buildMarkdown(String data) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: contentWidthFactor,
        child: MarkdownBody(
          data: data,
          onTapLink: (text, href, title) async {
            if (href != null) {
              final uri = Uri.parse(href);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not launch $href')),
                );
              }
            }
          },
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  // Build image widget
  Widget _buildImageWidget(String filename) {
    final String imgPath = '$mediaPath/$filename';

    return Center(
      child: FractionallySizedBox(
        widthFactor: contentWidthFactor,
        child: Image.asset(
          imgPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text('Image not found');
          },
        ),
      ),
    );
  }

  // Build video widget
  Widget _buildVideoWidget(String filename) {
    final String videoPath = '$mediaPath/$filename';
    VideoPlayerController controller;

    if (!_videoControllers.containsKey(filename)) {
      controller = VideoPlayerController.asset(videoPath)
        ..initialize().then((_) {
          setState(() {});
        });
      _videoControllers[filename] = controller;
    } else {
      controller = _videoControllers[filename]!;
    }

    return Center(
      child: FractionallySizedBox(
        widthFactor: contentWidthFactor,
        child: controller.value.isInitialized
            ? Column(
                children: [
                  AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                  VideoProgressIndicator(controller, allowScrubbing: true),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        onPressed: () {
                          setState(() {
                            controller.value.isPlaying
                                ? controller.pause()
                                : controller.play();
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop),
                        onPressed: () {
                          setState(() {
                            controller.seekTo(Duration.zero);
                            controller.pause();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }

  // Build audio widget
  Widget _buildAudioWidget(String filename) {
    final String audioAssetPath = 'media/$filename';
    AudioPlayer player;
    Duration? duration = _audioDurations[filename];
    Duration position = _audioPositions[filename] ?? Duration.zero;
    PlayerState? playerState = _audioPlayerStates[filename];

    if (!_audioPlayers.containsKey(filename)) {
      player = AudioPlayer();
      _audioPlayers[filename] = player;

      // Load the audio file
      player.setSource(AssetSource(audioAssetPath));

      // Listen for audio duration
      player.onDurationChanged.listen((Duration d) {
        setState(() {
          _audioDurations[filename] = d;
        });
      });

      // Listen for audio position
      player.onPositionChanged.listen((Duration p) {
        setState(() {
          _audioPositions[filename] = p;
        });
      });

      // Listen for player state changes
      player.onPlayerStateChanged.listen((PlayerState s) {
        setState(() {
          _audioPlayerStates[filename] = s;
        });
      });
    } else {
      player = _audioPlayers[filename]!;
    }

    // Get the current playing state
    playerState = _audioPlayerStates[filename];
    final isPlaying = playerState == PlayerState.playing;

    return Center(
      child: FractionallySizedBox(
        widthFactor: contentWidthFactor,
        child: Column(
          children: [
            // Progress bar
            Slider(
              value: position.inMilliseconds.toDouble(),
              min: 0.0,
              max: (duration?.inMilliseconds ?? 0).toDouble(),
              onChanged: (double value) {
                final newPosition = Duration(milliseconds: value.toInt());
                player.seek(newPosition);
              },
            ),
            // Button row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Play/pause button
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  onPressed: () {
                    if (isPlaying) {
                      player.pause();
                    } else {
                      player.resume();
                    }
                  },
                ),
                // Stop button
                IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: () {
                    player.stop();
                    setState(() {
                      _audioPositions[filename] = Duration.zero;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build the slider widget
  Widget _buildSlider(String name) {
    final sliderInfo = _sliders[name]!;
    final min = sliderInfo['min'];
    final max = sliderInfo['max'];
    final step = sliderInfo['step'];

    return Center(
      child: FractionallySizedBox(
        widthFactor: contentWidthFactor,
        child: Slider(
          value: _sliderValues[name]!,
          min: min,
          max: max,
          divisions: ((max - min) / step).round(),
          label: _sliderValues[name]!.toStringAsFixed(0),
          onChanged: (newValue) {
            setState(() {
              _sliderValues[name] = newValue;
            });
          },
        ),
      ),
    );
  }

  // Build radio group widget
  Widget _buildRadioGroup(String name, List<Map<String, String>> options) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: contentWidthFactor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: options.map((option) {
            return Row(
              children: [
                Radio<String>(
                  value: option['value']!,
                  groupValue: _radioValues[name],
                  onChanged: (String? newValue) {
                    setState(() {
                      _radioValues[name] = newValue;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    option['label']!,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // Build checkbox group widget
  Widget _buildCheckboxGroup(String name, List<Map<String, String>> options) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: contentWidthFactor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: options.map((option) {
            bool isChecked = _checkboxValues[name]!.contains(option['value']!);
            return Row(
              children: [
                Checkbox(
                  value: isChecked,
                  onChanged: (bool? newValue) {
                    setState(() {
                      if (newValue == true) {
                        _checkboxValues[name]!.add(option['value']!);
                      } else {
                        _checkboxValues[name]!.remove(option['value']!);
                      }
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    option['label']!,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // Build input field widget
  Widget _buildInputField(String name, {bool isMultiLine = false}) {
    // Ensure the controller is initialised
    if (!_textControllers.containsKey(name)) {
      _textControllers[name] = TextEditingController();
    }

    return Center(
      child: FractionallySizedBox(
        widthFactor: contentWidthFactor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            key: ValueKey('inputField_$name'),
            controller: _textControllers[name],
            maxLines: isMultiLine ? null : 1,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: name,
            ),
          ),
        ),
      ),
    );
  }

  // Build calendar field widget
  Widget _buildCalendarField(String name) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: contentWidthFactor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextFormField(
            readOnly: true,
            decoration: InputDecoration(
              // labelText: name,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  DateTime initialDate = _dateValues[name] ?? DateTime.now();
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                    builder: (BuildContext context, Widget? child) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(child: child!),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              setState(() {
                                _dateValues[name] = DateTime.now();
                              });
                            },
                            child: const Text('Today'),
                          ),
                        ],
                      );
                    },
                  );
                  if (pickedDate != null && pickedDate != _dateValues[name]) {
                    setState(() {
                      _dateValues[name] = pickedDate;
                    });
                  }
                },
              ),
            ),
            controller: TextEditingController(
              text: _dateValues[name] != null
                  ? '${_dateValues[name]!.year}-'
                      '${_dateValues[name]!.month.toString().padLeft(2, '0')}'
                      '-${_dateValues[name]!.day.toString().padLeft(2, '0')}'
                  : '',
            ),
          ),
        ),
      ),
    );
  }

  // Build dropdown widget
  Widget _buildDropdown(String name, List<String> options) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: contentWidthFactor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              // hintText: 'Select an option',
            ),
            value: _dropdownValues[name],
            items: options.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _dropdownValues[name] = newValue;
              });
            },
          ),
        ),
      ),
    );
  }

  // Build the menu
  Widget _buildMenu(String menuContent, String fullContent) {
    final lines = LineSplitter.split(menuContent).toList();
    final menuItems = <String>[];

    for (var line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.startsWith('- ')) {
        final item = trimmedLine.substring(2).trim();
        menuItems.add(item);
      }
    }

    final gridWidth = screenWidth(context) * contentWidthFactor;

    return Center(
      child: SizedBox(
        width: gridWidth,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: menuItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 items per row
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 4, // Ratio of button block width to height
          ),
          itemBuilder: (context, index) {
            final title = menuItems[index];
            return InkWell(
              onTap: () {
                // Extract the content for the selected survey
                final surveyContent =
                _extractSurveyContent(fullContent, title);

                // Call the callback to pass the menu item selection event to
                // the caller
                if (widget.onMenuItemSelected != null) {
                  widget.onMenuItemSelected!(title, surveyContent);
                }
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Extract the content of the survey with the given title
  String _extractSurveyContent(String markdownStr, String title) {
    final pattern = RegExp(
      r'^##\s+' + RegExp.escape(title) + r'\s*$',
      multiLine: true,
    );
    final matches = pattern.allMatches(markdownStr);

    if (matches.isEmpty) {
      return '';
    }

    // Get the position of the title
    final startIndex = matches.first.end;

    // Find the next second-level title or the end of the document
    final restOfDocument = markdownStr.substring(startIndex);
    final nextHeadingPattern = RegExp(r'^##\s+', multiLine: true);
    final nextMatch = nextHeadingPattern.firstMatch(restOfDocument);

    int endIndex;
    if (nextMatch != null) {
      endIndex = startIndex + nextMatch.start;
    } else {
      endIndex = markdownStr.length;
    }

    final content = markdownStr.substring(startIndex, endIndex).trim();
    return content;
  }

  @override
  Widget build(BuildContext context) {
    // Build content widgets every time to ensure UI updates
    final contentWidgets = _buildContentWidgets(widget.content);

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: contentWidgets,
      ),
    );
  }
}

// TimerWidget class
class TimerWidget extends StatefulWidget {
  final int totalSeconds;

  const TimerWidget({Key? key, required this.totalSeconds}) : super(key: key);

  @override
  _TimerWidgetState createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.totalSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning && !_isPaused) return;

    if (_isPaused) {
      // Resume the timer
      setState(() {
        _isPaused = false;
      });
    } else {
      // Start a new timer
      _isRunning = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingSeconds > 0 && !_isPaused) {
            _remainingSeconds--;
          } else if (_remainingSeconds == 0) {
            _timer?.cancel();
            _isRunning = false;
          }
        });
      });
    }
  }

  void _pauseTimer() {
    if (_isRunning && !_isPaused) {
      setState(() {
        _isPaused = true;
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = widget.totalSeconds;
      _isRunning = false;
      _isPaused = false;
    });
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final gridWidth = screenWidth(context) * contentWidthFactor;

    return Center(
      child: Container(
        width: gridWidth,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            Text(
              _formatTime(_remainingSeconds),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed:
                      _isRunning && !_isPaused ? _pauseTimer : _startTimer,
                  child: Text(_isRunning && !_isPaused ? 'Pause' : 'Start'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _resetTimer,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
