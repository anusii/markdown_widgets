/// Command parser for markdown widgets.
///
// Time-stamp: <Sunday 2024-11-17 21:00:21 +1100 Graham Williams>
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

import 'package:markdown_widget_builder/src/constants/pkg.dart';
import 'package:markdown_widget_builder/src/utils/helpers.dart';
import 'package:markdown_widget_builder/src/widgets/button_widget.dart';
import 'package:markdown_widget_builder/src/widgets/markdown_text.dart';
import 'package:markdown_widget_builder/src/widgets/menu_widget.dart';

class CommandParser {
  final BuildContext context;
  final String content;
  final String fullContent;
  final void Function(String title, String content)? onMenuItemSelected;
  final Map<String, dynamic> state;
  final VoidCallback setStateCallback;
  final String surveyTitle;

  late final Helpers helpers;

  late final Map<String, String> _inputValues;
  late final Map<String, double> _sliderValues;
  late final Map<String, Map<String, dynamic>> _sliders;
  late final Map<String, String?> _radioValues;
  late final Map<String, Set<String>> _checkboxValues;
  late final Map<String, DateTime?> _dateValues;
  late final Map<String, String?> _dropdownValues;
  late final Map<String, List<String>> _dropdownOptions;

  bool _hasMenu = false;

  CommandParser({
    required this.context,
    required this.content,
    required this.fullContent,
    this.onMenuItemSelected,
    required this.state,
    required this.setStateCallback,
    required this.surveyTitle,
  }) {
    // Initialise Helpers.

    helpers = Helpers(
      context: context,
      state: state,
      setStateCallback: setStateCallback,
    );

    // Initialise state variables.

    _inputValues = state['_inputValues'] as Map<String, String>;
    _sliderValues = state['_sliderValues'] as Map<String, double>;
    _sliders = state['_sliders'] as Map<String, Map<String, dynamic>>;
    _radioValues = state['_radioValues'] as Map<String, String?>;
    _checkboxValues = state['_checkboxValues'] as Map<String, Set<String>>;
    _dateValues = state['_dateValues'] as Map<String, DateTime?>;
    _dropdownValues = state['_dropdownValues'] as Map<String, String?>;
    _dropdownOptions = state['_dropdownOptions'] as Map<String, List<String>>;
  }

  List<Widget> parse() {
    List<Widget> widgets = [];

    // Regular expression to match description blocks.

    final RegExp descriptionBlockExp = RegExp(
        r'%% Description-Begin([\s\S]*?)%% Description-End',
        caseSensitive: false);

    // Regular expression to match heading blocks with alignment.

    final RegExp headingAlignBlockExp = RegExp(
        r'%% H([1-6])(Left|Right|Center|Justify)?'
        r'-Begin([\s\S]*?)%% H\1(?:\2)?-End',
        caseSensitive: false);

    // Regular expression to match alignment blocks.

    final RegExp alignBlockExp = RegExp(
        r'%% Align(Left|Right|Center|Justify)-Begin([\s\S]*?)%% Align\1-End',
        caseSensitive: false);

    // Regular expression to match image commands.

    final RegExp imageExp = RegExp(
        r'%% Image'
        r'\(\s*([^,\)]+)\s*(?:,\s*([\d\.]+)\s*)?(?:,\s*([\d\.]+)\s*)?\)',
        caseSensitive: false);

    // Regular expression to match video commands.

    final RegExp videoExp =
        RegExp(r'%% Video\(([^)]+)\)', caseSensitive: false);

    // Regular expression to match audio commands.

    final RegExp audioExp =
        RegExp(r'%% Audio\(([^)]+)\)', caseSensitive: false);

    // Regular expression to match %% Menu blocks.

    final RegExp menuBlockExp =
        RegExp(r'%% Menu-Begin([\s\S]*?)%% Menu-End', caseSensitive: false);

    String modifiedContent = content;

    // Parse the menu blocks and replace with placeholders.

    int menuIndex = 0;
    final Map<String, String> menuPlaceholders = {};
    modifiedContent = modifiedContent.replaceAllMapped(menuBlockExp, (match) {
      String placeholder = '%%MenuPlaceholder$menuIndex%%';
      menuPlaceholders[placeholder] = match.group(1)!;
      menuIndex++;
      return placeholder;
    });

    // Check if the content has a menu.

    _hasMenu = menuIndex > 0;

    // If there is a menu, trim the content to only process the menu part.

    if (_hasMenu) {
      // If there is a menu, only process the menu part and ignore the rest.

      final menuPlaceholderPattern = RegExp(r'%%MenuPlaceholder\d+%%');
      final menuMatch = menuPlaceholderPattern.firstMatch(modifiedContent);

      if (menuMatch != null) {
        // Keep only the content before the menu placeholder (including the menu
        // itself).

        final menuEndIndex = menuMatch.end;
        modifiedContent = modifiedContent.substring(0, menuEndIndex);
      }
    }

    // Parse the description blocks and replace with placeholders.

    int descriptionIndex = 0;
    final Map<String, String> descriptionPlaceholders = {};
    modifiedContent =
        modifiedContent.replaceAllMapped(descriptionBlockExp, (match) {
      String placeholder = '%%DescriptionPlaceholder$descriptionIndex%%';
      descriptionPlaceholders[placeholder] = match.group(1)!;
      descriptionIndex++;
      return placeholder;
    });

    // Parse heading blocks with alignment and replace with placeholders.

    int headingIndex = 0;
    final Map<String, Map<String, String>> headingPlaceholders = {};
    modifiedContent =
        modifiedContent.replaceAllMapped(headingAlignBlockExp, (match) {
      String placeholder = '%%HeadingPlaceholder$headingIndex%%';
      headingPlaceholders[placeholder] = {
        'level': match.group(1)!,
        'align': match.group(2) ?? 'Left',
        'content': match.group(3)!,
      };
      headingIndex++;
      return placeholder;
    });

    // Parse alignment blocks and replace with placeholders.

    int alignIndex = 0;
    final Map<String, Map<String, String>> alignPlaceholders = {};
    modifiedContent = modifiedContent.replaceAllMapped(alignBlockExp, (match) {
      String placeholder = '%%AlignPlaceholder$alignIndex%%';
      alignPlaceholders[placeholder] = {
        'align': match.group(1)!,
        'content': match.group(2)!
      };
      alignIndex++;
      return placeholder;
    });

    // Regular expression to match custom commands.

    final RegExp customCommandExp = RegExp(
        r'(%% Slider\([^\)]+\)|%% Submit|'
        r'%% Radio\([^\)]+\)|%% Checkbox\([^\)]+\)|'
        r'%% InputSL\([^\)]+\)|%% InputML\([^\)]+\)|'
        r'%% Calendar\([^\)]+\)|%% Dropdown\([^\)]+\)|'
        r'%% Image\([^\)]+\)|%% Video\([^\)]+\)|%% Audio\([^\)]+\)|'
        r'%% Timer\([^\)]+\)|%% Button\([^\)]+\)|%% EmptyLine|'
        r'%%DescriptionPlaceholder\d+%%|'
        r'%%HeadingPlaceholder\d+%%|'
        r'%%AlignPlaceholder\d+%%|'
        r'%%MenuPlaceholder\d+%%)',
        caseSensitive: false);

    final matches = customCommandExp.allMatches(modifiedContent).toList();

    int lastIndex = 0;

    // Parse the radio group variables.

    String? currentRadioGroupName;
    List<Map<String, String>> currentRadioOptions = [];

    // Parse the checkbox group variables.

    String? currentCheckboxGroupName;
    List<Map<String, String>> currentCheckboxOptions = [];

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      if (match.start > lastIndex) {
        // Extract the markdown content between custom commands.

        String markdownContent =
            modifiedContent.substring(lastIndex, match.start);
        if (markdownContent.trim().isNotEmpty) {
          // Build any unfinished radio or checkbox groups.

          if (currentRadioGroupName != null) {
            widgets.add(helpers.buildRadioGroup(
                currentRadioGroupName, currentRadioOptions));
            currentRadioGroupName = null;
            currentRadioOptions = [];
          }

          if (currentCheckboxGroupName != null) {
            widgets.add(helpers.buildCheckboxGroup(
                currentCheckboxGroupName, currentCheckboxOptions));
            currentCheckboxGroupName = null;
            currentCheckboxOptions = [];
          }

          widgets.add(MarkdownText(data: markdownContent));
        }
      }

      // Parse the command.

      String command = match.group(0)!;

      if (command
          .startsWith(RegExp(r'%%MenuPlaceholder', caseSensitive: false))) {
        // Get the actual menu content.

        String menuContent = menuPlaceholders[command]!;

        // Use the MenuWidget to build the menu.

        widgets.add(
          MenuWidget(
            menuContent: menuContent,
            fullContent: fullContent,
            onMenuItemSelected: (title, surveyContent) {
              if (onMenuItemSelected != null) {
                onMenuItemSelected!(title, surveyContent);
              }
            },
          ),
        );
      } else if (command.startsWith(
          RegExp(r'%%DescriptionPlaceholder', caseSensitive: false))) {
        // Description block placeholder to get the actual content.

        String descriptionContent = descriptionPlaceholders[command]!;

        // Add the description box directly to the widgets list.

        widgets.add(helpers.buildDescriptionBox(descriptionContent));
      } else if (command
          .startsWith(RegExp(r'%%HeadingPlaceholder', caseSensitive: false))) {
        // Heading block placeholder with alignment.

        final headingInfo = headingPlaceholders[command]!;
        final level = int.parse(headingInfo['level']!);
        final align = headingInfo['align']!;
        final headingContent = headingInfo['content']!;

        // Build the heading widget.

        widgets.add(helpers.buildHeading(level, headingContent, align));
      } else if (command
          .startsWith(RegExp(r'%%AlignPlaceholder', caseSensitive: false))) {
        // Alignment block placeholder.

        final alignInfo = alignPlaceholders[command]!;
        final align = alignInfo['align']!;
        final alignContent = alignInfo['content']!;

        // Build the aligned text widget.

        widgets.add(helpers.buildAlignedText(align, alignContent));
      } else if (command
          .startsWith(RegExp(r'%% Image', caseSensitive: false))) {
        final imageMatch = imageExp.firstMatch(command);
        if (imageMatch != null) {
          final filename = imageMatch.group(1)!.trim();
          double? width;
          double? height;

          if (imageMatch.group(2) != null) {
            width = double.tryParse(imageMatch.group(2)!.trim());
          }
          if (imageMatch.group(3) != null) {
            height = double.tryParse(imageMatch.group(3)!.trim());
          }

          widgets.add(
              helpers.buildImageWidget(filename, width: width, height: height));
        }
      } else if (command
          .startsWith(RegExp(r'%% Video', caseSensitive: false))) {
        final videoMatch = videoExp.firstMatch(command);
        if (videoMatch != null) {
          final filename = videoMatch.group(1)!.trim();
          widgets.add(helpers.buildVideoWidget(filename));
        }
      } else if (command
          .startsWith(RegExp(r'%% Audio', caseSensitive: false))) {
        final audioMatch = audioExp.firstMatch(command);
        if (audioMatch != null) {
          final filename = audioMatch.group(1)!.trim();
          widgets.add(helpers.buildAudioWidget(filename));
        }
      } else if (command
          .startsWith(RegExp(r'%% Timer', caseSensitive: false))) {
        // Build any unfinished radio or checkbox groups.

        if (currentRadioGroupName != null) {
          widgets.add(helpers.buildRadioGroup(
              currentRadioGroupName, currentRadioOptions));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }

        if (currentCheckboxGroupName != null) {
          widgets.add(helpers.buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        final timerExp = RegExp(r'%% Timer\(([^\)]+)\)', caseSensitive: false);
        final timerMatch = timerExp.firstMatch(command);

        if (timerMatch != null) {
          final timeString = timerMatch.group(1)!.trim();

          // Build the timer widget.

          widgets.add(helpers.buildTimerWidget(timeString));
        }
      } else if (command
          .startsWith(RegExp(r'%% EmptyLine', caseSensitive: false))) {
        // Build any unfinished radio or checkbox groups.

        if (currentRadioGroupName != null) {
          widgets.add(helpers.buildRadioGroup(
              currentRadioGroupName, currentRadioOptions));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }

        if (currentCheckboxGroupName != null) {
          widgets.add(helpers.buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        // Add an empty line.

        final lineHeight = DefaultTextStyle.of(context).style.fontSize ?? 16.0;
        widgets.add(SizedBox(height: lineHeight));
      } else if (command
          .startsWith(RegExp(r'%% Slider', caseSensitive: false))) {
        // Parse the slider parameters.

        final sliderExp = RegExp(
            r'%% Slider\(([^,]+),\s*([\d\.]+),'
            r'\s*([\d\.]+),\s*([\d\.]+),\s*([\d\.]+)\)',
            caseSensitive: false);
        final sliderMatch = sliderExp.firstMatch(command);

        if (sliderMatch != null) {
          final name = sliderMatch.group(1)!.trim();
          final min = double.parse(sliderMatch.group(2)!);
          final max = double.parse(sliderMatch.group(3)!);
          final defaultValue = double.parse(sliderMatch.group(4)!);
          final step = double.parse(sliderMatch.group(5)!);

          // Store the slider parameters.

          _sliders[name] = {
            'min': min,
            'max': max,
            'defaultValue': defaultValue,
            'step': step,
          };

          // Initialise the slider value.

          if (!_sliderValues.containsKey(name)) {
            _sliderValues[name] = defaultValue;
          }

          // Build the slider widget.

          widgets.add(helpers.buildSlider(name));
        }
      } else if (command.startsWith('%% Button')) {
        // Build any unfinished radio or checkbox groups.

        if (currentRadioGroupName != null) {
          widgets.add(helpers.buildRadioGroup(
              currentRadioGroupName, currentRadioOptions));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }

        if (currentCheckboxGroupName != null) {
          widgets.add(helpers.buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        // Create the ButtonWidget, passing the command and state variables.

        widgets.add(
          ButtonWidget(
            command: command,
            state: state,
            surveyTitle: surveyTitle,
          ),
        );
      } else if (command
          .startsWith(RegExp(r'%% Radio', caseSensitive: false))) {
        // Build any unfinished checkbox groups.

        if (currentCheckboxGroupName != null) {
          widgets.add(helpers.buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        final radioExp = RegExp(r'%% Radio\(([^,]+),\s*([^,]+),\s*([^\)]+)\)',
            caseSensitive: false);
        final radioMatch = radioExp.firstMatch(command);

        if (radioMatch != null) {
          final name = radioMatch.group(1)!.trim();
          final value = radioMatch.group(2)!.trim();
          final label = radioMatch.group(3)!.trim();

          // If starting a new radio group or the group name has changed.

          if (currentRadioGroupName == null || currentRadioGroupName != name) {
            // If there is a previous radio group, build it first.

            if (currentRadioGroupName != null) {
              widgets.add(helpers.buildRadioGroup(
                  currentRadioGroupName, currentRadioOptions));
              currentRadioOptions = [];
            }

            currentRadioGroupName = name;

            // Initialise the selected value of the group.

            if (!_radioValues.containsKey(name)) {
              _radioValues[name] = null;
            }
          }

          // Add options to the current group.

          currentRadioOptions.add({'value': value, 'label': label});

          // Check if the next command belongs to the same group.

          bool isLastOption = true;

          if (i + 1 < matches.length) {
            final nextMatch = matches[i + 1];
            final nextCommand = nextMatch.group(0)!;
            final nextRadioMatch = radioExp.firstMatch(nextCommand);
            if (nextRadioMatch != null) {
              final nextName = nextRadioMatch.group(1)!.trim();
              if (nextName.toLowerCase() ==
                  currentRadioGroupName.toLowerCase()) {
                isLastOption = false;
              }
            }
          }

          // If there are no more options, build the radio group.

          if (isLastOption) {
            widgets.add(helpers.buildRadioGroup(
                currentRadioGroupName, currentRadioOptions));
            currentRadioGroupName = null;
            currentRadioOptions = [];
          }
        }
      } else if (command
          .startsWith(RegExp(r'%% Checkbox', caseSensitive: false))) {
        // Build any unfinished radio groups.

        if (currentRadioGroupName != null) {
          widgets.add(helpers.buildRadioGroup(
              currentRadioGroupName, currentRadioOptions));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }

        final checkboxExp = RegExp(
            r'%% Checkbox\(([^,]+),\s*([^,]+),\s*([^\)]+)\)',
            caseSensitive: false);
        final checkboxMatch = checkboxExp.firstMatch(command);

        if (checkboxMatch != null) {
          final name = checkboxMatch.group(1)!.trim();
          final value = checkboxMatch.group(2)!.trim();
          final label = checkboxMatch.group(3)!.trim();

          // If starting a new checkbox group or the group name has changed.

          if (currentCheckboxGroupName == null ||
              currentCheckboxGroupName != name) {
            // If there is a previous checkbox group, build it first.

            if (currentCheckboxGroupName != null) {
              widgets.add(helpers.buildCheckboxGroup(
                  currentCheckboxGroupName, currentCheckboxOptions));
              currentCheckboxOptions = [];
            }

            currentCheckboxGroupName = name;

            // Initialise the selected values of the group.

            if (!_checkboxValues.containsKey(name)) {
              _checkboxValues[name] = {};
            }
          }

          // Add options to the current group.

          currentCheckboxOptions.add({'value': value, 'label': label});

          // Check if the next command belongs to the same group.

          bool isLastOption = true;
          if (i + 1 < matches.length) {
            final nextMatch = matches[i + 1];
            final nextCommand = nextMatch.group(0)!;
            final nextCheckboxMatch = checkboxExp.firstMatch(nextCommand);
            if (nextCheckboxMatch != null) {
              final nextName = nextCheckboxMatch.group(1)!.trim();
              if (nextName.toLowerCase() ==
                  currentCheckboxGroupName.toLowerCase()) {
                isLastOption = false;
              }
            }
          }

          // If there are no more options, build the checkbox group.

          if (isLastOption) {
            widgets.add(helpers.buildCheckboxGroup(
                currentCheckboxGroupName, currentCheckboxOptions));
            currentCheckboxGroupName = null;
            currentCheckboxOptions = [];
          }
        }
      } else if (command
          .startsWith(RegExp(r'%% Calendar', caseSensitive: false))) {
        // Build any unfinished radio or checkbox groups.

        if (currentRadioGroupName != null) {
          widgets.add(helpers.buildRadioGroup(
              currentRadioGroupName, currentRadioOptions));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }

        if (currentCheckboxGroupName != null) {
          widgets.add(helpers.buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        final calendarExp =
            RegExp(r'%% Calendar\(([^\)]+)\)', caseSensitive: false);
        final calendarMatch = calendarExp.firstMatch(command);

        if (calendarMatch != null) {
          final name = calendarMatch.group(1)!.trim();

          // Initialise date value.

          if (!_dateValues.containsKey(name)) {
            _dateValues[name] = null;
          }

          // Build the calendar field.

          widgets.add(helpers.buildCalendarField(name));
        }
      } else if (command
          .startsWith(RegExp(r'%% Dropdown', caseSensitive: false))) {
        // Build any unfinished radio or checkbox groups.

        if (currentRadioGroupName != null) {
          widgets.add(helpers.buildRadioGroup(
              currentRadioGroupName, currentRadioOptions));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }

        if (currentCheckboxGroupName != null) {
          widgets.add(helpers.buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        final dropdownExp =
            RegExp(r'%% Dropdown\(([^\)]+)\)', caseSensitive: false);
        final dropdownMatch = dropdownExp.firstMatch(command);

        if (dropdownMatch != null) {
          final name = dropdownMatch.group(1)!.trim();

          // Initialise dropdown options and selected value.

          if (!_dropdownValues.containsKey(name)) {
            _dropdownValues[name] = null;
          }

          if (!_dropdownOptions.containsKey(name)) {
            _dropdownOptions[name] = [];
          }

          // Parse the options from the following markdown list.

          int optionsStartIndex = match.end;
          int optionsEndIndex = modifiedContent.length;

          // Look ahead to find where the options list ends. It ends when a line
          // does not start with '-' or the next command starts.

          final lines =
              modifiedContent.substring(optionsStartIndex).split('\n');
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

          // Build the dropdown widget.

          widgets.add(helpers.buildDropdown(name, options));

          // Update the lastIndex to the end of the options list.

          lastIndex = optionsEndIndex;

          // Skip updating lastIndex again at the end of loop.

          continue;
        }
      }

      // Parse the input field command for single-line and multi-line input.

      else if (command
          .startsWith(RegExp(r'%% InputSL', caseSensitive: false))) {
        // Build any unfinished radio or checkbox groups.

        if (currentRadioGroupName != null) {
          widgets.add(helpers.buildRadioGroup(
              currentRadioGroupName, currentRadioOptions));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }

        if (currentCheckboxGroupName != null) {
          widgets.add(helpers.buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        final inputSLExp =
            RegExp(r'%% InputSL\(([^\)]+)\)', caseSensitive: false);
        final inputSLMatch = inputSLExp.firstMatch(command);

        if (inputSLMatch != null) {
          final name = inputSLMatch.group(1)!.trim();

          // Initialise the input value.

          if (!_inputValues.containsKey(name)) {
            _inputValues[name] = '';
          }

          widgets.add(helpers.buildInputField(name, isMultiLine: false));
        }
      } else if (command
          .startsWith(RegExp(r'%% InputML', caseSensitive: false))) {
        // Build any unfinished radio or checkbox groups.

        if (currentRadioGroupName != null) {
          widgets.add(helpers.buildRadioGroup(
              currentRadioGroupName, currentRadioOptions));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }

        if (currentCheckboxGroupName != null) {
          widgets.add(helpers.buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        final inputMLExp =
            RegExp(r'%% InputML\(([^\)]+)\)', caseSensitive: false);
        final inputMLMatch = inputMLExp.firstMatch(command);

        if (inputMLMatch != null) {
          final name = inputMLMatch.group(1)!.trim();

          // Initialise the input value.

          if (!_inputValues.containsKey(name)) {
            _inputValues[name] = '';
          }

          widgets.add(helpers.buildInputField(name, isMultiLine: true));
        }
      }

      lastIndex = match.end;
    }

    // Parse the markdown content after the last custom command.

    if (lastIndex < modifiedContent.length) {
      String markdownContent = modifiedContent.substring(lastIndex);
      if (markdownContent.trim().isNotEmpty) {
        // Build any unfinished radio or checkbox groups before adding new
        // content.

        if (currentRadioGroupName != null) {
          widgets.add(helpers.buildRadioGroup(
              currentRadioGroupName, currentRadioOptions));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }

        if (currentCheckboxGroupName != null) {
          widgets.add(helpers.buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        // If there is no menu, the content after the menu will need to be
        // shown.

        if (!_hasMenu) {
          widgets.add(MarkdownText(data: markdownContent));
        }
      }
    }

    // Build any unfinished radio or checkbox groups (if any).

    if (currentRadioGroupName != null) {
      widgets.add(
          helpers.buildRadioGroup(currentRadioGroupName, currentRadioOptions));
    }

    if (currentCheckboxGroupName != null) {
      widgets.add(helpers.buildCheckboxGroup(
          currentCheckboxGroupName, currentCheckboxOptions));
    }

    // Add some space at the end.

    final lineHeight = DefaultTextStyle.of(context).style.fontSize ?? 16.0;
    widgets.add(SizedBox(height: lineHeight * endingLines));

    return widgets;
  }
}
